provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# This provider is only suitable for "cluster-core" module
provider "kubernetes" {
  alias                  = "kubernetes-core"
  load_config_file       = false
  host                   = "https://${module.cluster-core.endpoint}"
  token                  = module.cluster-core.access_token
  cluster_ca_certificate = base64decode(module.cluster-core.cluster_ca_certificate)
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {
  depends_on = [module.cluster-core]
}

# Defer reading the cluster data until the GKE cluster exists.
data "google_container_cluster" "default" {
  name       = var.name
  location   = module.cluster-core.location
  depends_on = [module.cluster-core]
}

provider "kubernetes" {
  load_config_file = false
  host             = "https://${data.google_container_cluster.default.endpoint}"
  token            = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.default.master_auth[0].cluster_ca_certificate
  )
}

provider "kubernetes-alpha" {
  host  = "https://${data.google_container_cluster.default.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.default.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.default.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.default.master_auth[0].cluster_ca_certificate
    )
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
