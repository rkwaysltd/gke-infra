terraform {
  required_providers {

    kubernetes = {
      source = "hashicorp/kubernetes"
      # FIXME: see https://github.com/rkwaysltd/gke-infra/issues/15
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

  }
}
