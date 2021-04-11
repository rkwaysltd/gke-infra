variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in."
}

# https://cloud.google.com/load-balancing/docs/tcp#firewall_rules
variable "load_balancing_gfe_proxy_cidr" {
  description = "Configuration for GKE/Nginx load balancing: source IPs for Google Front End (GFE) proxies"
  type        = list(string)
}

