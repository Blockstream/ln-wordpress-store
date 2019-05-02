terraform {
  required_version = "> 0.11.0"

  backend "gcs" {
    bucket  = "ln-store"
    prefix  = "tf-state"
    project = "your-project"
  }
}

provider "google" {
  project = "${var.project}"
}

provider "google-beta" {
  project = "${var.project}"
}

module "ln-store" {
  source = "modules/ln-store"

  project       = "${var.project}"
  name          = "${var.name}"
  region        = "${var.region}"
  zone          = "${var.zone}"
  instance_type = "${var.instance_type}"
}
