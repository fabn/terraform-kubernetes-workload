# =============================================================================
# Ephemeral Storage Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

run "unset_by_default" {
  command = plan

  assert {
    condition     = !contains(keys(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].resources[0].requests), "ephemeral-storage")
    error_message = "No ephemeral-storage request should be rendered unless configured"
  }

  assert {
    condition     = !contains(keys(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].resources[0].limits), "ephemeral-storage")
    error_message = "No ephemeral-storage limit should be rendered unless configured"
  }
}

run "request_and_limit" {
  command = plan

  variables {
    memory_requests            = "256Mi"
    ephemeral_storage_requests = "6Gi"
    ephemeral_storage_limits   = "8Gi"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].resources[0].requests["ephemeral-storage"] == "6Gi"
    error_message = "ephemeral-storage request should be the configured value"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].resources[0].limits["ephemeral-storage"] == "8Gi"
    error_message = "ephemeral-storage limit should be the configured value"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].resources[0].requests["memory"] == "256Mi"
    error_message = "Memory request should be kept alongside ephemeral storage"
  }
}
