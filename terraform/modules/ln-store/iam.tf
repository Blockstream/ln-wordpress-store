resource "google_service_account" "store" {
  account_id   = "${var.name}"
  display_name = "LN Store SA"
}

resource "google_project_iam_member" "store" {
  project = "${var.project}"
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.store.email}"
}
