// Cluster-mid module should install all CRDs on the cluster
//
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

  }
}
