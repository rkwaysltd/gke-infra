module "legacy" {
  source = "./modules/legacy"

  project_id                                  = var.project_id
  name                                        = var.name
  region                                      = var.region
  zones                                       = var.zones
  machine_type                                = var.machine_type
  min_count                                   = var.min_count
  max_count                                   = var.max_count
  disk_size_gb                                = var.disk_size_gb
  initial_node_count                          = var.initial_node_count
  logs_retention_days                         = var.logs_retention_days
  ingress_rr_name                             = var.ingress_rr_name
  load_balancing_max_connections_per_endpoint = var.load_balancing_max_connections_per_endpoint
  cloudflare_api_token                        = var.cloudflare_api_token
  letsencrypt_email                           = var.letsencrypt_email
  cloudflare_api_email                        = var.cloudflare_api_email
  cloudflare_domain_list                      = var.cloudflare_domain_list
  cloudflare_domain_ingress_rr                = var.cloudflare_domain_ingress_rr
}
