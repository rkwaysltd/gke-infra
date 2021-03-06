terraform {
  required_providers {

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 1.13.3"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }

    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = ">= 0.3.2"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0"
    }

  }
}
