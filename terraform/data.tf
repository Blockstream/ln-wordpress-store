data "terraform_remote_state" "ln-store" {
  backend = "gcs"

  config {
    bucket  = "ln-store"
    prefix  = "tf-state"
    project = "your-project"
  }

  workspace = "default"
}
