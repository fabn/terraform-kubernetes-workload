# =============================================================================
# AWS ALB Ingress Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace         = "test-ns"
  name              = "test-app"
  image             = "nginx:latest"
  ports             = { http = 8080 }
  ingress_hostnames = ["app.example.com"]
}

# Test: ALB defaults add the listener and health check annotations
run "alb_default_annotations" {
  command = plan

  variables {
    alb = {}
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["alb.ingress.kubernetes.io/listen-ports"] == jsonencode([{ HTTPS = 443 }])
    error_message = "ALB should default to an HTTPS 443 listener"
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["alb.ingress.kubernetes.io/healthcheck-path"] == "/"
    error_message = "ALB should default the health check path to /"
  }

  assert {
    condition     = !contains(keys(kubernetes_ingress_v1.this[0].metadata[0].annotations), "alb.ingress.kubernetes.io/load-balancer-name")
    error_message = "Load balancer name annotation should be absent unless set"
  }
}

# Test: ALB suppresses in-cluster TLS and ACME even with their defaults on
run "alb_suppresses_tls_and_acme" {
  command = plan

  variables {
    alb = {}
  }

  assert {
    condition     = length(kubernetes_ingress_v1.this[0].spec[0].tls) == 0
    error_message = "spec.tls should be absent on ALB (TLS terminates on the load balancer)"
  }

  assert {
    condition     = !contains(keys(kubernetes_ingress_v1.this[0].metadata[0].annotations), "kubernetes.io/tls-acme")
    error_message = "ACME annotation should be suppressed on ALB"
  }
}

# Test: shared load balancer name
run "alb_load_balancer_name" {
  command = plan

  variables {
    alb = {
      load_balancer_name = "my-cluster-external"
    }
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["alb.ingress.kubernetes.io/load-balancer-name"] == "my-cluster-external"
    error_message = "Load balancer name annotation should carry the given name"
  }
}

# Test: custom listener ports and health check path
run "alb_custom_options" {
  command = plan

  variables {
    alb = {
      listen_ports     = [{ HTTP = 80 }, { HTTPS = 443 }]
      healthcheck_path = "/healthz"
    }
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["alb.ingress.kubernetes.io/listen-ports"] == jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
    error_message = "Listener ports should be configurable"
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["alb.ingress.kubernetes.io/healthcheck-path"] == "/healthz"
    error_message = "Health check path should be configurable"
  }
}

# Test: user annotations override ALB defaults
run "alb_user_annotations_win" {
  command = plan

  variables {
    alb = {}
    ingress_annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/status"
    }
  }

  assert {
    condition     = kubernetes_ingress_v1.this[0].metadata[0].annotations["alb.ingress.kubernetes.io/healthcheck-path"] == "/status"
    error_message = "User-provided annotations should override ALB defaults"
  }
}

# Test: no ALB annotations when alb is null
run "no_alb_annotations_by_default" {
  command = plan

  assert {
    condition     = !contains(keys(kubernetes_ingress_v1.this[0].metadata[0].annotations), "alb.ingress.kubernetes.io/listen-ports")
    error_message = "ALB annotations should be absent when alb is null"
  }

  assert {
    condition     = length(kubernetes_ingress_v1.this[0].spec[0].tls) == 1
    error_message = "Default TLS behaviour should be unchanged when alb is null"
  }
}
