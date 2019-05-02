# Terraform
Terraform is an API wrapper for different cloud providers. This configuration is only applicable to GCP. You can download `terraform` from here https://www.terraform.io/downloads.html.

# Before running
Make sure you've authenticated the `gcloud` SDK installed locally with GCP, similar to the way you would authenticate [Packer](../packer/ubuntu/README.md#before-running-packer) or add your credentials as an environment variable - https://www.terraform.io/docs/providers/google/getting_started.html#adding-credentials. 

# What's inside
There is a `ln-store` module that controls the creation of the instance, which is managed by an instance group and is based on an instance template. The instance template uses the latest image that was built by Packer in the `ln-store-ubuntu` family. Additionally, there's a [TCP load balancer](https://cloud.google.com/load-balancing/docs/network/setting-up-network) setup that forwards traffic to the instance.

There are a few mandatory things that will need to be updated:
* [data.tf](data.tf) - the GCS bucket that's storing the terraform state file
  * same GCS info has to be added to [main.tf](main.tf) as well
* [variables.tf](variables.tf) and [ln-store/variables.tf](modules/ln-store/variables.tf) - update your GCP project's name

# Useful Terraform commands
You can use `terraform plan` to verify changes.

If that looks good, you can apply the configuration with `terraform apply`.

In order to destroy infrastructure, you can use `terraform destroy`. If you want to destroy a specific resource, you can see what's already managed by Terraform `terraform state list`, then `terraform destroy -target name_from_list_above` (`-target` can be specified multiple times).