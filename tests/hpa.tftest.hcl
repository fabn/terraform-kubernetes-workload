# =============================================================================
# HPA Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No HPA by default
run "no_hpa_by_default" {
  command = plan

  assert {
    condition     = length(module.hpa) == 0
    error_message = "HPA should not be created by default"
  }
}

# Test: HPA enabled without config
run "hpa_enabled_without_config" {
  command = plan

  variables {
    hpa_enabled = true
  }

  assert {
    condition     = length(module.hpa) == 0
    error_message = "HPA should not be created without hpa_config"
  }
}

# Test: HPA enabled with config
run "hpa_enabled_with_config" {
  command = plan

  variables {
    hpa_enabled = true
    hpa_config = {
      min_replicas = 2
      max_replicas = 10
      metrics = {
        cpu_utilization = 70
      }
    }
  }

  assert {
    condition     = length(module.hpa) == 1
    error_message = "HPA should be created when enabled with config"
  }
}
