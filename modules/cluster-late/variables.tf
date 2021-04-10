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

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token for cert-manager"
  default     = ""
}

variable "letsencrypt_email" {
  type        = string
  description = "Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account."
  default     = ""
}

variable "cloudflare_api_email" {
  type        = string
  description = "Cloudflare API account for cert-manager"
  default     = ""
}

variable "cloudflare_domain_list" {
  type        = string
  description = "Comma separated list of domains for Cloudflare API token to manage."
  default     = ""
}
