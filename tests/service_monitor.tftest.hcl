# =============================================================================
# ServiceMonitor Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No ServiceMonitor by default
run "no_service_monitor_by_default" {
  command = plan

  assert {
    condition     = length(module.service_monitor) == 0
    error_message = "ServiceMonitor should not be created by default"
  }
}

# Test: ServiceMonitor enabled without ports
run "service_monitor_no_ports" {
  command = plan

  variables {
    service_monitor_enabled = true
  }

  assert {
    condition     = length(module.service_monitor) == 0
    error_message = "ServiceMonitor should not be created without ports"
  }
}

# Test: ServiceMonitor enabled with ports
run "service_monitor_with_ports" {
  command = plan

  variables {
    service_monitor_enabled = true
    ports = {
      http    = 8080
      metrics = 9090
    }
  }

  assert {
    condition     = length(module.service_monitor) == 1
    error_message = "ServiceMonitor should be created when enabled with ports"
  }
}

# Test: ServiceMonitor with custom config
run "service_monitor_custom_config" {
  command = plan

  variables {
    service_monitor_enabled = true
    ports                   = { metrics = 9090 }
    service_monitor_config = {
      port     = "metrics"
      path     = "/custom/metrics"
      interval = "15s"
    }
  }

  assert {
    condition     = length(module.service_monitor) == 1
    error_message = "ServiceMonitor should be created with custom config"
  }
}
