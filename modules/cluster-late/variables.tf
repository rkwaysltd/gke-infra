variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in."
}

variable "name" {
  type        = string
  description = "The name of the cluster."
}

variable "location" {
  type        = string
  description = "The location of the cluster."
}

variable "disk_encryption_key" {
  type        = string
  description = "The KMS key to encrypt PVs in all StorageClasses (as google_kms_crypto_key.x.self_link)."
}
