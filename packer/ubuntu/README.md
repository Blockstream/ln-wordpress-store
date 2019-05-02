# Deploy in the clouds
Make sure you have Packer installed - https://www.packer.io/intro/getting-started/install.html.

# Before running
First, you'll need to install the `gcloud` SDK (https://cloud.google.com/sdk/docs/quickstarts) and authenticate the SDK or a service account with your GCP project (https://www.packer.io/docs/builders/googlecompute.html#precedence-of-authentication-methods). Alternatively, if you're logging into your own GCP account, not a service account, you can use `gcloud auth login`, which will prompt you to sign in with your Google account that has access to GCP.

If you haven't already, you will need to create another service account in your GCP project, which Packer will use to create the bootable image (separate account from above). Follow these steps:

Go to the Google Cloud Console -> `IAM & Admin` -> `Service Accounts` -> `Create Service Account` -> Give it a name (ie packer) -> `Create` -> Select `Project Editor` role -> `Continue` -> `Create Key` and select JSON. This will download a service account file, which you'll have to move to the `packer/ubuntu/gcp/` directory so that Packer can use that service account to create the image.

Suggested changes to make in [user-data.sh](../../src/startup/user-data.sh) before building the image:
* Update the `rpcuser` and `rpcpassword` in [bitcoin.conf](../../src/startup/user-data.sh#L12) and [lightning.conf](../../src/startup/user-data.sh#L23)
* Decide if you want to run your nodes on [mainnet](../../README.md#switching-to-mainnet)
* Change Lightning Charge's [API Token](../../src/startup/user-data.sh#L112)
* Setup Wordpress
  * Change the [db-related](../../src/startup/user-data.sh#L355) settings and your site's [domain](../../src/startup/user-data.sh#L358)

# Deploy on GCP
```
cd gcp && packer build -var 'project_id=your_gcp_project' ln_store.json
```

## Single instance 
After the image has been created and published on GCP, go to Compute Engine -> Images -> select the image (`ln-store-ubuntu-timestamp`) and `Create Instance` from it (`n1-standard-4` should suffice).

## Terraform deployment
Another deployment option is to adapt the [terraform](../../terraform/) configuration and deploy an instance as part of an instance group with a Load Balancer in front of it so you can point DNS at the LB's IP.

## After deploying
* Run the [wp-setup script](../../src/startup/user-data.sh#L347): `bash /home/bs/wp-setup.sh`
* Consider adding `announce-addr=public.IP` to `/home/bs/lightning.conf` if you want to make your Lightning node public (you'll have to restart the `lightning.service` if you add that or make any other change to `lightning.conf` if the node is running)
* Enable Lightning Charge:
  * Get the IP of the Lightning Charge container: `docker inspect -f '{{ .NetworkSettings.IPAddress }}' charge`
  * Go to your site at `/wp-admin/` and login (default user: `lightning`, pw: `some-secure-password!`; make sure to update the default user and password via the UI or using `mysql-client` (`mysql -uroot -h127.0.0.1 -p`), the process is google-able)
  * Then, select WooCommerce -> Settings -> Payments -> Lightning -> Enable and change the API token to your updated token (default `SECRETAPITOKEN`) and the Charge server (i.e. the container) with the IP from the step above (`http://172.17.0.N:9112`) so that the Wordpress Lightning Gateway plugin can talk to Lightning Charge
* If you're on GCP and have pointed DNS at your [LB](#terraform-deployment), you can setup [HTTPS](../../README.md#setting-up-https-with-certbot)

If you're having problems with Wordpress, check the [troubleshooting](../../README.md#troubleshooting) section.