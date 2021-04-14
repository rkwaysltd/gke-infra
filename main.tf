module "cluster-core" {
  source = "./modules/cluster-core"

  providers = {
    # prevent cycles by using special provider
    kubernetes = kubernetes.kubernetes-core
  }

  project_id         = var.project_id
  name               = var.name
  region             = var.region
  zones              = var.zones
  machine_type       = var.machine_type
  min_count          = var.min_count
  max_count          = var.max_count
  disk_size_gb       = var.disk_size_gb
  initial_node_count = var.initial_node_count
}

module "cluster-mid" {
  source = "./modules/cluster-mid"

  project_id                    = var.project_id
  load_balancing_gfe_proxy_cidr = var.load_balancing_gfe_proxy_cidr

  depends_on = [module.cluster-core]
}

module "cluster-late" {
  source = "./modules/cluster-late"

  project_id                                  = var.project_id
  name                                        = var.name
  zones                                       = var.zones
  location                                    = module.cluster-core.location
  disk_encryption_key                         = module.cluster-core.storageclass_cmek_disk_encryption_key
  cert_manager_namespace                      = module.cluster-mid.cert_manager_namespace
  nginx_ingress_namespace                     = module.cluster-mid.nginx_ingress_namespace
  cloudflare_api_token                        = var.cloudflare_api_token
  letsencrypt_email                           = var.letsencrypt_email
  cloudflare_api_email                        = var.cloudflare_api_email
  cloudflare_domain_list                      = var.cloudflare_domain_list
  logs_retention_days                         = var.logs_retention_days
  logs_retention_days_cert_manager            = var.logs_retention_days_cert_manager
  logs_retention_days_nginx_ingress           = var.logs_retention_days_nginx_ingress
  load_balancing_network_tier                 = var.load_balancing_network_tier
  load_balancing_health_check_cidr            = var.load_balancing_health_check_cidr
  load_balancing_max_connections_per_endpoint = var.load_balancing_max_connections_per_endpoint
  cloudflare_domain_ingress_rr                = var.cloudflare_domain_ingress_rr
  ingress_rr_name                             = var.ingress_rr_name
  cloudflare_domain_ingress_proxied           = var.cloudflare_domain_ingress_proxied
  ingress_default_wildcard_certificate        = var.ingress_default_wildcard_certificate

  depends_on = [module.cluster-core, module.cluster-mid]
  count      = (var.terraform_preflight) ? 0 : 1
}
