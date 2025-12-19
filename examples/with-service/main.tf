# =============================================================================
# With Service Example
# =============================================================================
# This example shows a deployment with a ClusterIP service exposed.

module "api" {
  source = "../.."

  namespace = "default"
  name      = "my-api"
  image     = "my-registry/api:v1.0.0"

  # Container configuration
  replicas        = 2
  cpu_requests    = "100m"
  memory_requests = "256Mi"
  memory_limits   = "512Mi"

  # Expose ports - a ClusterIP service will be created
  ports = {
    http    = 8080
    metrics = 9090
  }

  # Health probes
  http_probe_path = "/health"
  probe_port      = "http"

  # Environment variables
  envs = {
    LOG_LEVEL = "info"
  }
}
