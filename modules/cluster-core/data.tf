data "google_project" "gke_project" {
  project_id = var.project_id
}

data "google_client_config" "default" {
}
