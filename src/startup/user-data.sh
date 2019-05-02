#!/bin/bash 

set -ex

# Check if /extra exists
ls /extra || sudo mkdir /extra

# Create bs user
ls /home/bs || sudo useradd -m -s /bin/bash bs

# Bitcoin and C-Lightning conf
cat <<- EOF > /home/bs/bitcoin.conf
# https://en.bitcoin.it/wiki/Running_Bitcoin
testnet=1
rpcuser=core
rpcpassword=chang3m3
txindex=1
dbcache=2000
EOF

chmod 0644 /home/bs/bitcoin.conf

cat <<- EOF > /home/bs/lightning.conf
# https://github.com/ElementsProject/lightning/tree/master/doc
network=testnet
alias=LN Store in a Box
bitcoin-rpcuser=core
bitcoin-rpcpassword=chang3m3
bind-addr=0.0.0.0
EOF

chmod 0644 /home/bs/lightning.conf

# Systemd services for bitcoin, c-lightning, charge
cat <<- EOF > /etc/systemd/system/bitcoin.service
[Unit]
Description=Bitcoin node
Wants=docker.service

[Service]
Restart=always
RestartSec=10
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull blockstream/bitcoind:latest
ExecStart=/usr/bin/docker run \
  --network=host \
  --pid=host \
  --name=bitcoin \
  --log-driver json-file --log-opt max-size=1g \
  -v /home/bs/bitcoin.conf:/root/.bitcoin/bitcoin.conf:ro \
  -v /extra/bitcoin:/root/.bitcoin \
  "blockstream/bitcoind:latest" bitcoind -printtoconsole
ExecStop=/usr/bin/docker exec bitcoin bitcoin-cli stop
ExecStopPost=/bin/sleep 3
ExecStopPost=/usr/bin/docker rm -f bitcoin

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/bitcoin.service

cat <<- EOF > /etc/systemd/system/lightning.service
[Unit]
Description=Lightning node
Wants=docker.service
After=bitcoin.service

[Service]
Restart=always
RestartSec=10
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull blockstream/lightningd:latest
ExecStartPre=/sbin/iptables -A INPUT -p tcp --dport 9735 -j ACCEPT
ExecStart=/usr/bin/docker run \
  --network=host \
  --pid=host \
  --name=lightning \
  --log-driver json-file --log-opt max-size=1g \
  -v /home/bs/lightning.conf:/root/.lightning/lightning.conf:ro \
  -v /extra/lightning:/root/.lightning \
  "blockstream/lightningd:latest" lightningd --conf=/root/.lightning/lightning.conf --plugin-dir=/usr/local/bin/plugins
ExecStop=/usr/bin/docker exec lightning lightning-cli stop
ExecStopPost=/bin/sleep 3
ExecStopPost=/usr/bin/docker rm -f lightning
ExecStopPost=/sbin/iptables -D INPUT -p tcp --dport 9735 -j ACCEPT

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/lightning.service

cat <<- EOF > /etc/systemd/system/charge.service
[Unit]
Description=Charge instance
Wants=docker.service
After=lightning.service

[Service]
Restart=always
RestartSec=10
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull blockstream/charged:latest
ExecStartPre=/sbin/iptables -A INPUT -p tcp -s localhost --dport 9112 -j ACCEPT
ExecStart=/usr/bin/docker run \
  --pid=host \
  --name=charge \
  -p 9112:9112 \
  -v /extra/lightning:/root/.lightning:ro \
  -v /extra/charge:/data \
  -e "API_TOKEN=SECRETAPITOKEN" \
  -e "DB_PATH=/data/charge.db" \
  -e "LN_PATH=/root/.lightning" \
  -e "HOST=0.0.0.0" \
  "blockstream/charged:latest" charged 
ExecStop=/usr/bin/docker stop charge
ExecStopPost=/usr/bin/docker rm -f charge
ExecStopPost=/sbin/iptables -D INPUT -p tcp -s localhost --dport 9112 -j ACCEPT

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/charge.service

# Wordpress stuff
cat <<- EOF > /etc/systemd/system/wp.service
[Unit]
Description=Wordpress instance
Wants=docker.service

[Service]
Restart=always
RestartSec=5
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull wordpress:php7.3-fpm-alpine
ExecStartPre=/usr/bin/docker run \
  --user root \
  -v /extra/data/wp:/var/www/html \
  --entrypoint bash \
  --rm \
  "wordpress:php7.3-fpm-alpine" -c 'chown -R www-data:www-data /var/www/html'
ExecStart=/usr/bin/docker run \
  --pid=host \
  --name=wp \
  --link=wp-mysql \
  -v /extra/data/wp:/var/www/html \
  -e "WORDPRESS_DB_USER=root" \
  -e "WORDPRESS_DB_PASSWORD=my-secret-pw" \
  -e "WORDPRESS_DB_HOST=wp-mysql" \
  "wordpress:php7.3-fpm-alpine"
ExecStop=/usr/bin/docker stop wp
ExecStopPost=/usr/bin/docker rm -f wp

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/wp.service

cat <<- EOF > /etc/systemd/system/mysql.service
[Unit]
Description=MySQL db for Wordpress
Wants=docker.service

[Service]
Restart=always
RestartSec=5
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull mysql:5.7
ExecStartPre=/usr/bin/docker run \
  --user root \
  -v /extra/data/db:/var/lib/mysql \
  --entrypoint bash \
  --rm \
  "mysql:5.7" -c 'chown -R mysql:mysql /var/lib/mysql'
ExecStart=/usr/bin/docker run \
  --pid=host \
  --name=wp-mysql \
  -v /extra/data/db:/var/lib/mysql \
  -p 3306:3306 \
  -e "MYSQL_ROOT_PASSWORD=my-secret-pw" \
  "mysql:5.7"
ExecStop=/usr/bin/docker stop wp-mysql
ExecStopPost=/usr/bin/docker rm -f wp-mysql

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/mysql.service

cat <<- EOF > /etc/systemd/system/nginx.service
[Unit]
Description=Nginx reverse proxy
Wants=docker.service
After=wp.service

[Service]
Restart=always
RestartSec=5
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull nginx:latest
ExecStart=/usr/bin/docker run \
  --pid=host \
  --name=wp-nginx \
  --link=wp \
  -v /extra/data/wp:/var/www/html:ro \
  -v /etc/letsencrypt/archive/example.com/:/var/www/html/letsencrypt:ro \
  -v /home/bs/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  -p 80:8080 \
  -p 443:443 \
  "nginx:latest"
ExecStop=/usr/bin/docker stop wp-nginx
ExecStopPost=/usr/bin/docker rm -f wp-nginx

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/nginx.service

cat <<- EOF > /etc/systemd/system/wp-cli.service
[Unit]
Description=Wordpress CLI for setup
Wants=docker.service
After=wp.service

[Service]
Type=simple
Environment=HOME=/home/bs
ExecStartPre=/usr/bin/docker pull wordpress:cli
ExecStart=/usr/bin/docker run \
  --pid=host \
  --name=wp-cli \
  --link=wp-mysql \
  -v /extra/data/wp:/var/www/html \
  -e "WORDPRESS_DB_PASSWORD=my-secret-pw" \
  "wordpress:cli" bash -c 'sleep 600'
ExecStop=/usr/bin/docker stop wp-cli
ExecStopPost=/usr/bin/docker rm -f wp-cli

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/wp-cli.service

cat <<- 'EOF' > /home/bs/nginx.conf
log_format withtime '$remote_addr - $remote_user [$time_local] '
      '"$request" $status $body_bytes_sent '
      '"$http_referer" "$http_user_agent" '
      'rt="$request_time" uct="$upstream_connect_time" uht="$upstream_header_time" urt="$upstream_response_time"';

server {
  index index.php index.html index.htm index.nginx-debian.html;

  access_log /dev/stdout withtime;
  error_log /dev/stdout info;

  server_name _;
  listen 8080 default_server;
  set_real_ip_from 130.211.0.0/22;
  set_real_ip_from 35.191.0.0/16;
  set_real_ip_from 10.0.0.0/8;
  real_ip_recursive on;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

  location /.well-known {
      alias /var/www/html/.well-known;
      auth_basic off;
      allow all; # Allow all to see content
  }

  location / {
      return 301 https://$host$request_uri;
  }
  
  location /health.html {
      return 200;
  }

  location ~ /\.ht {
      deny all;
  }
}

# server {
#   index index.php index.html index.htm index.nginx-debian.html;
# 
#   access_log /dev/stdout withtime;
#   error_log /dev/stdout info;
# 
#   server_name _;
#   listen 443 ssl;
# 
#   client_max_body_size 100M;
#   root /var/www/html;
#   server_tokens off;
#   set_real_ip_from 130.211.0.0/22;
#   set_real_ip_from 35.191.0.0/16;
#   set_real_ip_from 10.0.0.0/8;
#   real_ip_recursive on;
#   proxy_set_header Host $host;
#   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
# 
#   ssl_certificate /var/www/html/letsencrypt/fullchain1.pem;
#   ssl_certificate_key /var/www/html/letsencrypt/privkey1.pem;
#   ssl_prefer_server_ciphers on;
# 
#   location / {
#       try_files $uri $uri/ /index.php$is_args$args;
#   }
# 
#   location ~ \.php$ {
#       # regex to split $uri to $fastcgi_script_name and $fastcgi_path
#       fastcgi_split_path_info ^(.+\.php)(/.+)$;
# 
#       # Check that the PHP script exists before passing it
#       try_files $fastcgi_script_name =404;
# 
#       # Bypass the fact that try_files resets $fastcgi_path_info
#       # see: http://trac.nginx.org/nginx/ticket/321
#       set $path_info $fastcgi_path_info;
#       fastcgi_param PATH_INFO $path_info;
# 
#       fastcgi_index index.php;
# 
#       include fastcgi_params;
#       fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#       fastcgi_param PATH_INFO $fastcgi_path_info;
# 
#       fastcgi_pass wp:9000;
#   }
# 
#   location ~ /\.ht {
#       deny all;
#   }
#}
EOF

chmod 0644 /home/bs/nginx.conf

# Wordpress setup script
cat <<- EOF > /home/bs/wp-setup.sh
#!/bin/env bash

systemctl start wp-cli

sleep 5 # wait for service

# Install wp-config.php
docker exec wp-cli sh -c 'wp config create --dbname=wordpress --dbuser=root --dbpass=my-secret-pw --dbhost=wp-mysql --force'

# Update domain
# If you want to test on localhost, you can replace "example.com" with just "localhost"
docker exec wp-cli sh -c 'wp search-replace "localhost:8080" "example.com" --skip-columns=guid'

EOF

chmod 0744 /home/bs/wp-setup.sh

# Install docker, certbot, mysql-client
cat <<- 'EOF' > /home/bs/prereqs.sh
#!/bin/env bash

set -ex

SUCCESS_INDICATOR=/opt/.provision_success

# confirm this is an ubuntu box
[[ ! -f /etc/lsb-release ]] && exit 1

# check if vagrant_provision has run before
[[ -f $SUCCESS_INDICATOR ]] && exit 0

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
add-apt-repository ppa:certbot/certbot -y
apt-get update && apt-get upgrade -y && apt-get install -qfy docker-ce software-properties-common certbot mysql-client
echo ""

# Successful run
touch $SUCCESS_INDICATOR

exit 0
EOF

chmod 0744 /home/bs/prereqs.sh

bash /home/bs/prereqs.sh
systemctl daemon-reload
systemctl enable bitcoin.service
systemctl enable lightning.service
systemctl enable charge.service
systemctl enable wp.service
systemctl enable mysql.service
systemctl enable nginx.service
