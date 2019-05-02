# LN-Store-in-a-Box Overview
This repository represents a basic plug-and-play setup for a Wordpress-based Lightning Store.
 
Vagrant is used to build a VM locally for testing and configuration. Packer is used to create a bootable image on GCP/AWS. See the respective directories for more details - [vagrant/ubuntu/](vagrant/ubuntu/) and [packer/ubuntu/](packer/ubuntu/). Additionally, there is a simple Terraform setup for deploying an instance on GCP based on the Packer image. It requires some small changes before being applied - see [terraform/](terraform/).

The suggested workflow is:
* Clone this repository
* [Test Wordpress locally](#testing-and-modifying-wordpress-locally)
* [Use Vagrant to provision an Ubuntu VM](vagrant/ubuntu/)
  * This is not a mandatory step, but it won't cost you anything compared to making changes directly to an instance on GCP/AWS
* [Create a Packer image and deploy](packer/ubuntu/)

# Contents

* [Architecture](#architecture)
* [Testing Wordpress locally](#testing-and-modifying-wordpress-locally)
* [Running on mainnet](#switching-to-mainnet)
* [Setting up HTTPS](#setting-up-https-with-certbot)
* [Troubleshooting](#troubleshooting)

# Architecture
There are 5 major components running in tandem to make the store work out of the box.
1. **Bitcoind**
  * Testnet full node that C-Lightning relies on (see [below](#switching-to-mainnet) how to switch to mainnet)
  * https://github.com/bitcoin/bitcoin

2. **C-Lightning**
  * Lightning Network node
  * https://github.com/ElementsProject/lightning

3. **Lightning Charge**
  * REST API for Wordpress to interact with C-Lightning
  * https://github.com/ElementsProject/lightning-charge, https://github.com/ElementsProject/woocommerce-gateway-lightning

4. **Wordpress** (plus an Nginx reverse-proxy)
  * A generic site has been included in `data/wp/` with a few fake products and the minimum plugins needed for the site - WooCommerce + Lightning Charge Gateway
  * https://codex.wordpress.org/

5. **MySQL** db for Wordpress
  * There is a `data/db/` included as well to make the Wordpress site work properly (there shouldn't be any secrets in the provided dir)
  * https://dev.mysql.com/doc/

You don't need to rely on the current setup. It is meant to get you started with a basic store, which will require some modifications based on your needs. Make sure to change all the default passwords, tokens, etc.

# Testing and modifying Wordpress locally
If you want to play around and/or setup Wordpress locally, you can just run `make setup`. Just make sure you have [docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce) and [docker-compose](https://docs.docker.com/compose/install/) installed. The `docker-compose` file is a direct replica of the way the Wordpress, MySQL and Nginx `systemd` services are setup in the [user-data](src/startup/) file. Also, the included `data/wp/` and `data/db/` directories are mounted in the containers.

After the containers have been setup, you can access the site and login at [http://localhost:8080/wp-admin/](http://localhost:8080/wp-admin/) with user: `lightning`, pw: `some-secure-password!`. You can add products, logos, additional plugins, change themes, etc. at this point. All changes will persist in the Wordpress and database mounted directories.

# Switching to mainnet
You will need to make these changes in order to run your Bitcoin and Lightning nodes on mainnet:
* Change to `testnet=0` in the [bitcoin.conf](src/startup/user-data.sh#L14)
* Change to `network=bitcoin` in the [lightning.conf](src/startup/user-data.sh#L25)

*Warning*: Be mindful of reusing the same bitcoin/lightning directories when/if you're switching between testnet and mainnet. It's not always a great idea and it may result in loss of funds on mainnet! It's best practice to wipe the lightning directory when switching networks, otherwise C-Lightning won't start, so be careful when you're switching networks and when you're deleting/renaming directories. 

# Setting up HTTPS with Certbot
Certbot has been installed by the [prereqs.sh](src/startup/user-data.sh#L365) script. You can install a cert by creating a challenge file in `/extra/data/wp/.well-known/acme-challenge/challenge_file` by running these commands and following the on-screen instructions:
```
certbot register --agree-tos -m email@example.com
certbot certonly --manual -d example.com
```
During the cert creation, you'll get a prompt that's similar to this:
```
Create a file containing just this data:

eEoRsQAiP4k_obCm5aLY3GGOioIw2il4p4JHnvW8CFc.l00bktMdD9DBdubjjGznSAuSQTo1HVuUAIw-5HQzbsI

And make it available on your web server at this URL:

http://example.com/.well-known/acme-challenge/eEoRsQAiP4k_obCm5aLY3GGOioIw2il4p4JHnvW8CFc

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```
So, create that file in `/extra/data/wp/.well-known/acme-challenge` by:
```
echo "eEoRsQAiP4k_obCm5aLY3GGOioIw2il4p4JHnvW8CFc.l00bktMdD9DBdubjjGznSAuSQTo1HVuUAIw-5HQzbsI" > /extra/data/wp/.well-known/acme-challenge/eEoRsQAiP4k_obCm5aLY3GGOioIw2il4p4JHnvW8CFc
```
After you get the "Congratulations!" response from Certbot, you'll have to uncomment the SSL server block in `/home/bs/nginx.conf`, update the [/etc/systemd/system/nginx.service](src/startup/user-data.sh#L210) with your domain and finally restart the Nginx service `systemctl daemon-reload && systemctl restart nginx`. You should have HTTPS setup now. 

Cert renewal:

Add this line to `/etc/crontab`:
```
0  */12 * * *   root    test -x /usr/bin/certbot && { date; certbot renew --preferred-challenges dns; systemctl restart nginx; } >> /tmp/debug 2>&1
```

*Note*: If you don't want to run HTTPS for some reason or you're just testing things, you can take the location directives from the SSL server [block](src/startup/user-data.sh#L290) and put them in the http server [block](src/startup/user-data.sh#L256). After moving those, you can delete or leave the SSL server block commented out.

# Troubleshooting
Things to check if something's not working as expected:

* Check that all *6* services are running
```
sudo systemctl status bitcoin lightning charge mysql wp nginx | grep active | wc -l
```
* Double-check `wp-setup` and try setting up `wp-config.php` again

```
bash /home/bs/wp-setup.sh
```
* Play around with the Wordpress-CLI

You can install/uninstall themes, plugins, modify the MySQL db and much more (make sure the `wp-cli` service has been started - `systemctl start wp-cli`).
```
docker exec -it wp-cli bash
wp --help
```

# TODO
* Don't include wp/db data in repo directly
* Make stuff more idempotent
* AWS AMI 
* CoreOS version
* Create a config file, which will be used by a bootstrap script; or something similar
* Automate most of the deployment/provisioning process