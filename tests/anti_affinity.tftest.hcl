# =============================================================================
# Anti-Affinity Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: Soft anti-affinity by default
run "soft_anti_affinity_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity) == 1
    error_message = "Affinity should be configured by default"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].preferred_during_scheduling_ignored_during_execution) == 1
    error_message = "Soft anti-affinity should be configured by default"
  }
}

# Test: Hard anti-affinity
run "hard_anti_affinity" {
  command = plan

  variables {
    anti_affinity = "hard"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].required_during_scheduling_ignored_during_execution) == 1
    error_message = "Hard anti-affinity should be configured"
  }
}

# Test: No anti-affinity
run "no_anti_affinity" {
  command = plan

  variables {
    anti_affinity = null
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity) == 0
    error_message = "No affinity should be configured when anti_affinity is null"
  }
}
