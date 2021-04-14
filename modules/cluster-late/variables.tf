variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in."
}

variable "name" {
  type        = string
  description = "The name of the cluster."

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.name))
    error_message = "The cluster name should only contain A-Z, a-z, 0-9 and '-' character. Cannot start with '-'."
  }
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the cluster in. Single entry means it's zonal cluster. Multiple entries for regional clusters."
}

variable "location" {
  type        = string
  description = "The location of the cluster."
}

variable "disk_encryption_key" {
  type        = string
  description = "The KMS key to encrypt PVs in all StorageClasses (as google_kms_crypto_key.x.self_link)."
}

variable "cert_manager_namespace" {
  type        = string
  description = "The name of Namespace with Cert Manager."
}

variable "nginx_ingress_namespace" {
  type        = string
  description = "The name of Namespace with Nginx Ingress Controller."
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

locals {
  cloudflare_domain_list = [for domain in split(",", var.cloudflare_domain_list) : trimspace(domain)]
}

variable "logs_retention_days" {
  type        = number
  description = "Logs will be retained by default for this amount of time, after which they will automatically be deleted. The minimum retention period is 1 day."
}

variable "logs_retention_days_cert_manager" {
  type        = number
  description = "Logs retention for cert-manager namespace in days. The minimum retention period is 1 day."
}

variable "logs_retention_days_nginx_ingress" {
  type        = number
  description = "Logs retention for nginx-ingress namespace in days. The minimum retention period is 1 day."
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

# https://cloud.google.com/load-balancing/docs/tcp#firewall_rules
variable "load_balancing_health_check_cidr" {
  description = "Configuration for GKE/Nginx load balancing: source IPs for health checks"
  type        = list(string)
}

# https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#max-worker-connections
variable "load_balancing_max_connections_per_endpoint" {
  description = "Configuration for GKE/Nginx load balancing: max_connections_per_endpoint based on default max-worker-connections (but ignores number of workers in Pod)"
  type        = number
}

variable "cloudflare_domain_ingress_rr" {
  type        = string
  description = "Domain name with ingress A record. Should be one of 'cloudflare_domain_list'."

  # No validation as the condition for variable can only refer to the variable itself
  #validation {
  #  condition     = contains(local.cloudflare_domain_list, var.cloudflare_domain_ingress_rr)
  #  error_message = "Not in the cloudflare_domain_list."
  #}
}

variable "ingress_rr_name" {
  type        = string
  description = "The name of the ingress A-type resource record in DNS.."
}

variable "cloudflare_domain_ingress_proxied" {
  type        = bool
  description = "Enable Cloudflare proxy for ingress RR."
}

variable "ingress_default_wildcard_certificate" {
  type        = bool
  description = "Enable wildcard certificate on ingress domain."
}
