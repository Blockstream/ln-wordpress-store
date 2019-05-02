# Testing locally
This Vagrant configuration is meant for testing your setup locally first before provisioning the Packer image on someone else's server.

The way to use Vagrant is to provision an Ubuntu VM locally to test your configuration. This will allow you to make the necessary changes in the [user-data.sh](../../src/startup/user-data.sh) script before creating a deployable image. You can setup your store however you want and make all the necessary Wordpress (including MySQL) changes in the VM and build the image after that so you have less changes to make on the instance on GCP/AWS.

## TODOs before running:
* Create a `/extra` with `bitcoin/`, `lightning/`, and `charge/` directories. Copy `data/` dir from the cloned repo into `/extra`. Vagrant will sync your local `/extra` to a directory in the VM. Make sure to check out the [user-data.sh](../../src/startup/user-data.sh) for details on how the directories are mounted and used in the containers. Also, it may not be a bad idea to sync your testnet/mainnet node before creating the store (i.e. rsync a tar with bitcoind's datadir); if not, that's fine as well
* There's some basic `.conf` files provided for bitcoind and c-lightning, so feel free to edit those as needed
* Edit the [Wordpress](../../src/startup/user-data.sh#L128) and [MySQL](../../src/startup/user-data.sh#L162) services to make sure they're using appropriate passwords, env vars, settings, etc.
* Edit the [wp-setup.sh](../../src/startup/user-data.sh#L347) script to configure Wordpress appropriately (passwords, db info, etc.); you can also install additional WP plugins, or you can just install them in the UI, which is simpler to use than `wp-cli`

*Note*: Be aware that mounting `/extra` in the [C-Lightning container](../../src/startup/user-data.sh#L81) may not work, so you'll have to switch to a Docker volume instead (`-v lightning:/root/.lightning`). The same change needs to be applied to [Lightning Charge](../../src/startup/user-data.sh#L110) since it needs access to the `lightning-rpc` socket file.
Also, if you get weird MySQL errors, the above should "fix" it - instead of using `/extra/data/db`, you'll need to update the `mysql.service` file to:
```
...
--user root \
-v db:/var/lib/mysql \
--entrypoint bash \
...
--name=wp-mysql \
-v db:/var/lib/mysql \
-p 3306:3306 \
...
```
You need to: 
* stop the `mysql.service` 
* update the `mysql.service` file 
* `systemctl daemon-reload`
* `systemctl restart mysql` 
* remove the volume directory's contents (`docker volume inspect db` to get the path) - `rm -rf /var/lib/docker/volumes/db/_data/*`
* copy `data/db/` to the volume's directory - `cp -R /extra/data/db/* /var/lib/docker/volumes/db/_data/`
* and `systemctl restart mysql` again

## Install Vagrant on Ubuntu:
```
wget https://releases.hashicorp.com/vagrant/2.2.4/vagrant_2.2.4_x86_64.deb
dpkg -i vagrant_2.2.4_x86_64.deb
```

Or other operating systems https://www.vagrantup.com/downloads.html.

## Run Vagrant:
```
sudo vagrant up
sudo vagrant ssh
```
### Inside Vagrant:
Start all services:
```
sudo systemctl start bitcoin lightning charge mysql
sudo systemctl start wp nginx
```

## Verify everything's running:
You should be able to access your website locally (outside the Vagrant VM) on `localhost/wp-admin` (user: `lightning`, pw: `some-secure-password!`). If you're running Vagrant on a remote server that you have SSH'd into, just port-forward port 80 to your laptop (e.g. `ssh -L 8080:localhost:80 server`).

If you're having problems, check the [troubleshooting](../../README.md#troubleshooting) section.

Parts of this setup were stolen from https://github.com/craighurley/vagrant-cloud-init.
