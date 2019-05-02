resource "google_compute_instance_group_manager" "store" {
  name     = "${var.name}-ig"
  provider = "google-beta"

  base_instance_name = "${var.name}-ig"
  target_pools       = ["${google_compute_target_pool.store.self_link}"]
  zone               = "${var.zone}"
  target_size        = 1

  version {
    name              = "original"
    instance_template = "${google_compute_instance_template.store.self_link}"
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 0
    max_unavailable_fixed = 1
    min_ready_sec         = 60
  }
}

resource "google_compute_disk" "store" {
  name  = "${var.name}-boot"
  type  = "pd-standard"
  image = "${data.google_compute_image.store.self_link}"
  zone  = "${var.zone}"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["image"]
  }
}

# Instance template
resource "google_compute_instance_template" "store" {
  name_prefix  = "${var.name}-tmpl-"
  description  = "This template is used to create ${var.name} instances."
  machine_type = "${var.instance_type}"
  region       = "${var.region}"

  labels {
    type = "lightning-store"
    name = "${var.name}"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source      = "${google_compute_disk.store.name}"
    auto_delete = false
    boot        = true
  }

  network_interface {
    network = "${data.google_compute_network.store.self_link}"

    access_config {
    }
  }

  metadata {
    google-logging-enabled = "true"
  }

  service_account {
    email  = "${google_service_account.store.email}"
    scopes = ["compute-ro", "storage-ro"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
