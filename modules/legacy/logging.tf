# all non-audit logs unless directed elsewhere
resource "google_logging_project_bucket_config" "default" {
  project        = var.project_id
  location       = "global"
  retention_days = var.logs_retention_days
  bucket_id      = "_Default"
}

# Example: cert-manager logs (keep for 30 days)
resource "google_logging_project_bucket_config" "cert_manager" {
  project        = var.project_id
  location       = "global"
  retention_days = 30
  bucket_id      = "cert-manager"
}

resource "google_logging_project_sink" "cert_manager" {
  name                   = "cert-manager"
  destination            = "logging.googleapis.com/${google_logging_project_bucket_config.cert_manager.id}"
  filter                 = "resource.type = k8s_container resource.labels.namespace_name=\"${kubernetes_namespace.cert_manager.metadata[0].name}\" "
  unique_writer_identity = true
}

resource "google_logging_project_exclusion" "cert_manager" {
  name        = "cert-manager"
  description = "Exclude cert-manager namespace logs. Stored elsewhere."
  filter      = "resource.type = k8s_container resource.labels.namespace_name=\"${kubernetes_namespace.cert_manager.metadata[0].name}\" "
}
