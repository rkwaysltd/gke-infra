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
  description = "The zones to host the cluster in. Single entry means it's zonal cluster. Multiple entries for regional clusters."
}

variable "name" {
  type        = string
  description = "The name of the cluster."
}

variable "ingress_rr_name" {
  type        = string
  description = "The name of the ingress A-type resource record in DNS.."
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

variable "cloudflare_domain_ingress_rr" {
  type        = string
  description = "Domain name with ingress A record. Should be one of 'cloudflare_domain_list'."
  default     = ""
}

variable "cloudflare_domain_ingress_proxied" {
  type        = bool
  description = "Enable Cloudflare proxy for ingress RR."
  default     = false
}

# https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#max-worker-connections
variable "load_balancing_max_connections_per_endpoint" {
  description = "Configuration for GKE/Nginx load balancing: max_connections_per_endpoint based on default max-worker-connections (but ignores number of workers in Pod)"
  type        = number
  default     = 16384
}

# https://cloud.google.com/load-balancing/docs/tcp#firewall_rules
variable "load_balancing_health_check_cidr" {
  description = "Configuration for GKE/Nginx load balancing: source IPs for health checks"
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}

# https://cloud.google.com/load-balancing/docs/tcp#firewall_rules
variable "load_balancing_gfe_proxy_cidr" {
  description = "Configuration for GKE/Nginx load balancing: source IPs for Google Front End (GFE) proxies"
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}

# https://cloud.google.com/load-balancing/docs/tcp#load-balancer-behavior-in-network-service-tiers
variable "load_balancing_network_tier" {
  description = "Configuration for GKE/Nginx load balancing: Network Tier for traffic"
  type        = string
  default     = "PREMIUM"

  validation {
    condition     = can(regex("^(PREMIUM|STANDARD)$", var.load_balancing_network_tier))
    error_message = "Must be PREMIUM or STANDARD."
  }
}
