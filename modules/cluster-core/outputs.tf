output "kubernetes_endpoint" {
  sensitive = true
  value     = module.gke.endpoint
}

output "client_token" {
  sensitive = true
  value     = base64encode(data.google_client_config.default.access_token)
}

output "ca_certificate" {
  sensitive = true
  value     = module.gke.ca_certificate
}

output "service_account" {
  description = "The default service account used for running nodes."
  value       = module.gke.service_account
}

output "location" {
  description = "The location of the cluster."
  value       = module.gke.location
}

output "storageclass_cmek_disk_encryption_key" {
  description = "The KMS key that should be used for PVs Encryption-at-Rest."
  value       = google_kms_crypto_key.sc_storageclass_cmek_disk.self_link
}
