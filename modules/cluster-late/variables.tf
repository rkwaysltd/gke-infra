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
}

variable "letsencrypt_email" {
  type        = string
  description = "Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account."
}

variable "cloudflare_api_email" {
  type        = string
  description = "Cloudflare API account for cert-manager"
}

variable "cloudflare_domain_list" {
  type        = string
  description = "Comma separated list of domains for Cloudflare API token to manage."
}

variable "logs_retention_days" {
  type        = number
  description = "Logs will be retained by default for this amount of time, after which they will automatically be deleted. The minimum retention period is 1 day."
}

# https://cloud.google.com/load-balancing/docs/tcp#load-balancer-behavior-in-network-service-tiers
variable "load_balancing_network_tier" {
  description = "Configuration for GKE/Nginx load balancing: Network Tier for traffic"
  type        = string

  validation {
    condition     = can(regex("^(PREMIUM|STANDARD)$", var.load_balancing_network_tier))
    error_message = "Must be PREMIUM or STANDARD."
  }
}
