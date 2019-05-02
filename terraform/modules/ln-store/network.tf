# Backend service
resource "google_compute_backend_service" "store" {
  name        = "${var.name}-backend-service"
  description = "Lightning Store in a Box"
  protocol    = "HTTP"
  port_name   = "http"

  backend {
    group = "${google_compute_instance_group_manager.store.instance_group}"
  }

  health_checks = ["${google_compute_http_health_check.store.self_link}"]
}

# Health checks
resource "google_compute_http_health_check" "store" {
  name = "${var.name}-http-health-check"
  port = "80"
  
  request_path = "/health.html"
  check_interval_sec = 5
  timeout_sec        = 3
}

# Firewall rules
resource "google_compute_firewall" "store" {
  name    = "${var.name}-fw-rule"
  network = "${data.google_compute_network.store.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["18333", "8333", "9735", "80", "443"]
  }

  target_service_accounts = [
    "${google_service_account.store.email}",
  ]
}

# Target pool
resource "google_compute_target_pool" "store" {
  name   = "${var.name}-target-pool"
  region = "${var.region}"

  health_checks = [
    "${google_compute_http_health_check.store.self_link}",
  ]
}

# LB IP address
resource "google_compute_address" "lb" {
  name    = "${var.name}-client-lb"
  project = "${var.project}"
  region  = "${var.region}"
}

# Forwarding rules
resource "google_compute_forwarding_rule" "http" {
  name        = "${var.name}-http-forwarding-rule"
  target      = "${google_compute_target_pool.store.self_link}"
  ip_address  = "${google_compute_address.lb.address}"
  region      = "${var.region}"
  port_range  = "80"
  ip_protocol = "TCP"
  count       = 1
}

resource "google_compute_forwarding_rule" "https" {
  name        = "${var.name}-https-forwarding-rule"
  target      = "${google_compute_target_pool.store.self_link}"
  ip_address  = "${google_compute_address.lb.address}"
  region      = "${var.region}"
  port_range  = "443"
  ip_protocol = "TCP"
  count       = 1
}
