# =============================================================================
# Rollout Strategy Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: unset, no strategy block is rendered and Kubernetes keeps its defaults
run "default_strategy" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].strategy) == 0
    error_message = "No strategy block should be rendered when rolling_update is null"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].min_ready_seconds == null
    error_message = "minReadySeconds should be left unset, so the provider's default of 0 applies"
  }
}

# Test: replace in place, the setting for hard anti-affinity on a tight pool
run "replace_in_place" {
  command = plan

  variables {
    replicas          = 2
    anti_affinity     = "hard"
    rolling_update    = { max_surge = "0", max_unavailable = "1" }
    min_ready_seconds = 15
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].strategy[0].type == "RollingUpdate"
    error_message = "Strategy type should be RollingUpdate"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].strategy[0].rolling_update[0].max_surge == "0"
    error_message = "maxSurge should be the configured value"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].strategy[0].rolling_update[0].max_unavailable == "1"
    error_message = "maxUnavailable should be the configured value"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].min_ready_seconds == 15
    error_message = "minReadySeconds should be the configured value"
  }
}

# Test: a field left out keeps the Kubernetes default
run "partial_rolling_update" {
  command = plan

  variables {
    rolling_update = { max_unavailable = "1" }
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].strategy[0].rolling_update[0].max_surge == "25%"
    error_message = "An omitted max_surge should default to 25%"
  }
}

# Test: both zero would stall every rollout
run "both_zero_rejected" {
  command = plan

  variables {
    rolling_update = { max_surge = "0%", max_unavailable = "0" }
  }

  expect_failures = [var.rolling_update]
}

# Test: values must be an integer or a percentage
run "malformed_value_rejected" {
  command = plan

  variables {
    rolling_update = { max_surge = "one", max_unavailable = "1" }
  }

  expect_failures = [var.rolling_update]
}

# Test: negative minReadySeconds is rejected
run "negative_min_ready_seconds_rejected" {
  command = plan

  variables {
    min_ready_seconds = -1
  }

  expect_failures = [var.min_ready_seconds]
}
