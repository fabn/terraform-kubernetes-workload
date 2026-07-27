# =============================================================================
# Tolerations Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: no tolerations by default => spec.tolerations is empty
run "no_tolerations_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].toleration) == 0
    error_message = "No tolerations should be rendered by default"
  }
}

# Test: tolerations are rendered verbatim into spec.tolerations
run "tolerations_rendered" {
  command = plan

  variables {
    tolerations = [
      { key = "example.com/dedicated", operator = "Exists", effect = "NoSchedule" },
      { key = "dedicated", operator = "Equal", value = "database", effect = "NoExecute", toleration_seconds = 30 },
    ]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].toleration) == 2
    error_message = "Both tolerations should be rendered"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].toleration[0].key == "example.com/dedicated"
    error_message = "First toleration key should be preserved"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].toleration[0].operator == "Exists"
    error_message = "First toleration operator should be preserved"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].toleration[1].toleration_seconds == "30"
    error_message = "toleration_seconds should be preserved"
  }
}
