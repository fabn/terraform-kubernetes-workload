# =============================================================================
# With Ingress Example
# =============================================================================
# This example shows a deployment with service and ingress for external access.

module "web" {
  source = "../.."

  namespace = "production"
  name      = "my-web"
  image     = "my-registry/web:v1.0.0"

  # Container configuration
  replicas        = 3
  cpu_requests    = "200m"
  memory_requests = "512Mi"
  memory_limits   = "1Gi"

  # Port configuration
  ports = {
    http = 3000
  }

  # Health probes
  http_probe_path = "/api/health"
  probe_port      = "http"

  # Ingress configuration
  ingress_hostnames   = ["app.example.com", "www.example.com"]
  ingress_class_name  = "nginx"
  ingress_tls_enabled = true
  ingress_annotations = {
    "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
  }

  # Pod scheduling
  anti_affinity = "soft"
}
