# =============================================================================
# Service Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No service when no ports defined
run "no_service_without_ports" {
  command = plan

  assert {
    condition     = length(kubernetes_service_v1.this) == 0
    error_message = "Service should not be created without ports"
  }
}

# Test: No service when service_type is null
run "no_service_when_type_null" {
  command = plan

  variables {
    ports        = { http = 8080 }
    service_type = null
  }

  assert {
    condition     = length(kubernetes_service_v1.this) == 0
    error_message = "Service should not be created when service_type is null"
  }
}

# Test: ClusterIP service created with ports
run "clusterip_service" {
  command = plan

  variables {
    ports = { http = 8080 }
  }

  assert {
    condition     = length(kubernetes_service_v1.this) == 1
    error_message = "Service should be created when ports are defined"
  }

  assert {
    condition     = kubernetes_service_v1.this[0].spec[0].type == "ClusterIP"
    error_message = "Default service type should be ClusterIP"
  }

  assert {
    condition     = kubernetes_service_v1.this[0].metadata[0].name == "test-app"
    error_message = "Service name should match var.name"
  }
}

# Test: LoadBalancer service type
run "loadbalancer_service" {
  command = plan

  variables {
    ports        = { http = 8080 }
    service_type = "LoadBalancer"
  }

  assert {
    condition     = kubernetes_service_v1.this[0].spec[0].type == "LoadBalancer"
    error_message = "Service type should be LoadBalancer"
  }
}

# Test: Multiple ports
run "multiple_ports" {
  command = plan

  variables {
    ports = {
      http    = 8080
      metrics = 9090
      grpc    = 50051
    }
  }

  assert {
    condition     = length(kubernetes_service_v1.this[0].spec[0].port) == 3
    error_message = "Service should have 3 ports"
  }
}
