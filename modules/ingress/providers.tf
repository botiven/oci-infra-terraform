terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.45.0"
    }
  }
}
