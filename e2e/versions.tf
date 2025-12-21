terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 1.0.0"
    }
  }
}
