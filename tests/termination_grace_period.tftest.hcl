# =============================================================================
# Termination Grace Period Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: an explicit budget reaches the pod spec
run "explicit_grace_period" {
  command = plan

  variables {
    termination_grace_period_seconds = 90
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].termination_grace_period_seconds == 90
    error_message = "terminationGracePeriodSeconds should be the configured value"
  }
}

# Test: zero is allowed — it means "kill immediately", which is a legitimate
# choice for a stateless pod with nothing to flush.
run "zero_grace_period" {
  command = plan

  variables {
    termination_grace_period_seconds = 0
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].termination_grace_period_seconds == 0
    error_message = "A zero grace period should be rendered, not treated as unset"
  }
}

# Test: negative values are rejected rather than passed to the API server
run "negative_grace_period_rejected" {
  command = plan

  variables {
    termination_grace_period_seconds = -1
  }

  expect_failures = [var.termination_grace_period_seconds]
}
