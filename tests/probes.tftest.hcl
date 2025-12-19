# =============================================================================
# Health Probes Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No probes by default
run "no_probes_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].liveness_probe) == 0
    error_message = "No liveness probe should be configured by default"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].readiness_probe) == 0
    error_message = "No readiness probe should be configured by default"
  }
}

# Test: HTTP probes configured
run "http_probes" {
  command = plan

  variables {
    http_probe_path = "/health"
    ports           = { http = 8080 }
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].liveness_probe) == 1
    error_message = "Liveness probe should be configured"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].liveness_probe[0].http_get[0].path == "/health"
    error_message = "Liveness probe path should be /health"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].readiness_probe) == 1
    error_message = "Readiness probe should be configured"
  }
}

# Test: Startup probe with different path
run "startup_probe_different_path" {
  command = plan

  variables {
    http_probe_path    = "/health"
    startup_probe_path = "/health/startup"
    ports              = { http = 8080 }
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].startup_probe[0].http_get[0].path == "/health/startup"
    error_message = "Startup probe should use different path"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].liveness_probe[0].http_get[0].path == "/health"
    error_message = "Liveness probe should use http_probe_path"
  }
}

# Test: Custom probe port
run "custom_probe_port" {
  command = plan

  variables {
    http_probe_path = "/health"
    probe_port      = "metrics"
    ports = {
      http    = 8080
      metrics = 9090
    }
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].liveness_probe[0].http_get[0].port == "metrics"
    error_message = "Probe port should be metrics"
  }
}
