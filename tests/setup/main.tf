# =============================================================================
# Test Provider Configuration
# =============================================================================
# This setup module configures the Kubernetes provider for testing.
# Uses KUBE_CONFIG_PATH environment variable set by CI.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Test namespace for isolation
resource "kubernetes_namespace_v1" "test" {
  metadata {
    name = "workload-test"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-test"
    }
  }
}

output "namespace" {
  value = kubernetes_namespace_v1.test.metadata[0].name
}
