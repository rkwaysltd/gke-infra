provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${module.cluster-core.kubernetes_endpoint}"
  token                  = module.cluster-core.client_token
  cluster_ca_certificate = base64decode(module.cluster-core.ca_certificate)
}

provider "kubernetes-alpha" {
  host                   = "https://${module.cluster-core.kubernetes_endpoint}"
  token                  = module.cluster-core.client_token
  cluster_ca_certificate = base64decode(module.cluster-core.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.cluster-core.kubernetes_endpoint}"
    token                  = module.cluster-core.client_token
    cluster_ca_certificate = base64decode(module.cluster-core.ca_certificate)
  }
}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
