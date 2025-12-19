# =============================================================================
# Ingress Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
  ports     = { http = 8080 }
}

# Test: No ingress when no hostnames defined
run "no_ingress_without_hostnames" {
  command = plan

  assert {
    condition     = length(kubernetes_ingress_v1.this) == 0
    error_message = "Ingress should not be created without hostnames"
  }
}

# Test: Ingress created with hostnames
run "ingress_with_hostnames" {
  command = plan

  variables {
    ingress_hostnames = ["app.example.com"]
  }

  assert {
    condition     = length(kubernetes_ingress_v1.this) == 1
    error_message = "Ingress should be created with hostnames"
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].name == "test-app"
    error_message = "Ingress name should match var.name"
  }
}

# Test: Multiple hostnames
run "multiple_hostnames" {
  command = plan

  variables {
    ingress_hostnames = ["app.example.com", "www.example.com"]
  }

  assert {
    condition     = length(kubernetes_ingress_v1.this[0].spec[0].rule) == 2
    error_message = "Ingress should have 2 rules for 2 hostnames"
  }
}

# Test: TLS enabled by default
run "tls_enabled_by_default" {
  command = plan

  variables {
    ingress_hostnames = ["app.example.com"]
  }

  assert {
    condition     = length(kubernetes_ingress_v1.this[0].spec[0].tls) == 1
    error_message = "TLS should be enabled by default"
  }
}

# Test: TLS disabled
run "tls_disabled" {
  command = plan

  variables {
    ingress_hostnames   = ["app.example.com"]
    ingress_tls_enabled = false
  }

  assert {
    condition     = length(kubernetes_ingress_v1.this[0].spec[0].tls) == 0
    error_message = "TLS should be disabled when ingress_tls_enabled is false"
  }
}

# Test: Custom TLS secret name
run "custom_tls_secret" {
  command = plan

  variables {
    ingress_hostnames       = ["app.example.com"]
    ingress_tls_secret_name = "custom-tls-secret"
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].spec[0].tls[0].secret_name == "custom-tls-secret"
    error_message = "TLS secret name should be custom-tls-secret"
  }
}

# Test: Ingress class name
run "ingress_class_name" {
  command = plan

  variables {
    ingress_hostnames  = ["app.example.com"]
    ingress_class_name = "nginx"
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].spec[0].ingress_class_name == "nginx"
    error_message = "Ingress class name should be nginx"
  }
}

# Test: Custom annotations
run "custom_annotations" {
  command = plan

  variables {
    ingress_hostnames = ["app.example.com"]
    ingress_annotations = {
      "nginx.ingress.kubernetes.io/proxy-body-size" = "100m"
    }
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["nginx.ingress.kubernetes.io/proxy-body-size"] == "100m"
    error_message = "Custom annotation should be set"
  }
}

# Test: ACME annotation enabled by default
run "acme_annotation_enabled" {
  command = plan

  variables {
    ingress_hostnames = ["app.example.com"]
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["kubernetes.io/tls-acme"] == "true"
    error_message = "ACME annotation should be enabled by default"
  }
}

# Test: Canary deployment
run "canary_deployment" {
  command = plan

  variables {
    ingress_hostnames = ["app.example.com"]
    canary = {
      enabled = true
      weight  = 20
    }
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["nginx.ingress.kubernetes.io/canary"] == "true"
    error_message = "Canary annotation should be true"
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["nginx.ingress.kubernetes.io/canary-weight"] == "20"
    error_message = "Canary weight should be 20"
  }
}
