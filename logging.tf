# all non-audit logs unless directed elsewhere
resource "google_logging_project_bucket_config" "default" {
  project        = var.project_id
  location       = "global"
  retention_days = var.logs_retention_days
  bucket_id      = "_Default"
}
