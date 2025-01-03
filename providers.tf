terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.15.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.45.0"
    }
  }
}

resource "local_file" "kubeconfig" {
  content  = module.oci.k8s_kubeconfig
  filename = "${path.module}/kubeconfig"
}

provider "oci" {
  region = var.region
}

provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
