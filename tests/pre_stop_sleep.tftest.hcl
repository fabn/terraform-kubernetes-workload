# =============================================================================
# preStop Sleep Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: no lifecycle block by default, so existing users see no plan change
run "no_hook_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].lifecycle) == 0
    error_message = "The main container should have no lifecycle block by default"
  }
}

# Test: zero is the same as unset
run "zero_means_no_hook" {
  command = plan

  variables {
    pre_stop_sleep_seconds = 0
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].lifecycle) == 0
    error_message = "pre_stop_sleep_seconds = 0 should not render a lifecycle block"
  }
}

# Test: the configured delay renders a preStop sleep on the main container
run "pre_stop_sleep_configured" {
  command = plan

  variables {
    pre_stop_sleep_seconds           = 20
    termination_grace_period_seconds = 45
    sidecar_containers = [
      { name = "sidecar", command = ["/bin/sidecar"] }
    ]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].lifecycle[0].pre_stop[0].exec[0].command == tolist(["sleep", "20"])
    error_message = "The main container preStop hook should sleep for the configured seconds"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].lifecycle) == 0
    error_message = "Sidecar containers should not get the preStop hook"
  }
}

# Test: the delay fits within the default 30s grace period when it is unset
run "fits_default_grace_period" {
  command = plan

  variables {
    pre_stop_sleep_seconds = 15
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].lifecycle[0].pre_stop[0].exec[0].command == tolist(["sleep", "15"])
    error_message = "A delay below the default grace period should be accepted"
  }
}

# Test: negative values are rejected
run "negative_rejected" {
  command = plan

  variables {
    pre_stop_sleep_seconds = -1
  }

  expect_failures = [var.pre_stop_sleep_seconds]
}

# Test: fractional values are rejected
run "fractional_rejected" {
  command = plan

  variables {
    pre_stop_sleep_seconds = 2.5
  }

  expect_failures = [var.pre_stop_sleep_seconds]
}

# Test: a delay that does not fit in the grace period is rejected
run "not_lower_than_grace_period_rejected" {
  command = plan

  variables {
    pre_stop_sleep_seconds           = 30
    termination_grace_period_seconds = 30
  }

  expect_failures = [kubernetes_deployment_v1.this]
}

# Test: the default 30s grace period applies when it is unset
run "exceeds_default_grace_period_rejected" {
  command = plan

  variables {
    pre_stop_sleep_seconds = 40
  }

  expect_failures = [kubernetes_deployment_v1.this]
}
