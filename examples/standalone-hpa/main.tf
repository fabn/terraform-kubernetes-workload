# =============================================================================
# Standalone HPA Example
# =============================================================================
# This example shows how to use the HPA submodule independently,
# for example to add autoscaling to an existing deployment.

module "hpa" {
  source = "../../modules/hpa"

  namespace = "production"
  name      = "existing-deployment-hpa"

  # Reference to an existing deployment
  target_ref = {
    api_version = "apps/v1"
    kind        = "Deployment"
    name        = "existing-deployment"
  }

  # Scaling configuration
  min_replicas = 2
  max_replicas = 10

  # Metrics
  metrics = {
    cpu_utilization    = 70
    memory_utilization = 80

    # Custom pod metrics (requires Prometheus Adapter or similar)
    pod_metrics = {
      "requests_per_second" = "100"
    }
  }

  # Labels
  labels = {
    "app.kubernetes.io/name"       = "existing-deployment"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}
