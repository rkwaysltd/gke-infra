variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in."
}

variable "region" {
  type        = string
  description = "The region to host the cluster in."
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the cluster in."
}

variable "name" {
  type        = string
  description = "The name of the cluster."
}

variable "machine_type" {
  type        = string
  description = "Type of the node compute engines."
}

variable "min_count" {
  type        = number
  description = "Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count."
}

variable "max_count" {
  type        = number
  description = "Maximum number of nodes in the NodePool. Must be >= min_node_count."
}

variable "disk_size_gb" {
  type        = number
  description = "Size of the node's disk."
}

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
}

variable "logs_retention_days" {
  type        = number
  description = "Logs will be retained by default for this amount of time, after which they will automatically be deleted. The minimum retention period is 1 day."
}

variable "letsencrypt_email" {
  type        = string
  description = "Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account."
  default     = ""
}

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token for cert-manager"
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
