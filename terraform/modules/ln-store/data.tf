data "google_compute_network" "store" {
  name = "default"
}

data "google_compute_image" "store" {
  family  = "ln-store-ubuntu"
  project = "${var.project}"
}
