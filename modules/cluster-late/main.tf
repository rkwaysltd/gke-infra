terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      # FIXME: see https://github.com/rkwaysltd/gke-infra/issues/15
      version = ">= 1.13.3"
    }
  }
}
