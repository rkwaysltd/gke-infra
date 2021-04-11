terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      # Tested on 3.63.0, review required before switching to > 4.0.0
      version = ">= 3.63.0, < 4.0.0"
    }
  }
}
