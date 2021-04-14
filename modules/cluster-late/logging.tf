# all non-audit logs unless directed elsewhere
resource "google_logging_project_bucket_config" "default" {
  project        = var.project_id
  location       = "global"
  retention_days = var.logs_retention_days
  bucket_id      = "_Default"
}

# Pod-label logging
resource "google_logging_project_bucket_config" "pod_label" {
  for_each = toset(local.logs_retention_bylabel_buckets)

  project        = var.project_id
  location       = "global"
  retention_days = each.value
  bucket_id      = "keep-logs-${each.value}-days"
}

resource "google_logging_project_sink" "pod_label" {
  for_each = toset(local.logs_retention_bylabel_buckets)

  name                   = "keep-logs-${each.value}-days"
  destination            = "logging.googleapis.com/${google_logging_project_bucket_config.pod_label[each.value].id}"
  # `rkways.com` from Pod label changes into `rkways_com`
  filter                 = "resource.type = k8s_container labels.\"k8s-pod/rkways_com/gke-infra-logdays\" = \"${each.value}\" "
  unique_writer_identity = true
}

resource "google_logging_project_exclusion" "pod_label" {
  for_each = toset(local.logs_retention_bylabel_buckets)

  name        = "keep-logs-${each.value}-days"
  description = "Exclude Pod-labelled logs. Stored elsewhere."
  filter                 = "resource.type = k8s_container labels.\"k8s-pod/rkways_com/gke-infra-logdays\" = \"${each.value}\" "
}

# cert-manager logs
resource "google_logging_project_bucket_config" "cert_manager" {
  project        = var.project_id
  location       = "global"
  retention_days = var.logs_retention_days_cert_manager
  bucket_id      = "cert-manager"
}

resource "google_logging_project_sink" "cert_manager" {
  name                   = "cert-manager"
  destination            = "logging.googleapis.com/${google_logging_project_bucket_config.cert_manager.id}"
  filter                 = "resource.type = k8s_container resource.labels.namespace_name=\"${var.cert_manager_namespace}\" "
  unique_writer_identity = true
}

resource "google_logging_project_exclusion" "cert_manager" {
  name        = "cert-manager"
  description = "Exclude cert-manager namespace logs. Stored elsewhere."
  filter      = "resource.type = k8s_container resource.labels.namespace_name=\"${var.cert_manager_namespace}\" "
}

# nginx-ingress logs
resource "google_logging_project_bucket_config" "nginx_ingress" {
  project        = var.project_id
  location       = "global"
  retention_days = var.logs_retention_days_nginx_ingress
  bucket_id      = "nginx-ingress"
}

resource "google_logging_project_sink" "nginx_ingress" {
  name                   = "nginx-ingress"
  destination            = "logging.googleapis.com/${google_logging_project_bucket_config.nginx_ingress.id}"
  filter                 = "resource.type = k8s_container resource.labels.namespace_name=\"${var.nginx_ingress_namespace}\" "
  unique_writer_identity = true
}

resource "google_logging_project_exclusion" "nginx_ingress" {
  name        = "nginx-ingress"
  description = "Exclude nginx-ingress namespace logs. Stored elsewhere."
  filter      = "resource.type = k8s_container resource.labels.namespace_name=\"${var.nginx_ingress_namespace}\" "
}
