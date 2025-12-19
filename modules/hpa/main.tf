# =============================================================================
# Horizontal Pod Autoscaler
# =============================================================================

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  metadata {
    namespace = var.namespace
    name      = var.name
    labels    = var.labels
  }

  spec {
    scale_target_ref {
      api_version = var.target_ref.api_version
      kind        = var.target_ref.kind
      name        = var.target_ref.name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # CPU utilization metric
    dynamic "metric" {
      for_each = var.metrics.cpu_utilization != null ? [1] : []
      content {
        type = "Resource"
        resource {
          name = "cpu"
          target {
            type                = "Utilization"
            average_utilization = var.metrics.cpu_utilization
          }
        }
      }
    }

    # Memory utilization metric
    dynamic "metric" {
      for_each = var.metrics.memory_utilization != null ? [1] : []
      content {
        type = "Resource"
        resource {
          name = "memory"
          target {
            type                = "Utilization"
            average_utilization = var.metrics.memory_utilization
          }
        }
      }
    }

    # Custom pod metrics
    dynamic "metric" {
      for_each = var.metrics.pod_metrics
      content {
        type = "Pods"
        pods {
          metric {
            name = metric.key
          }
          target {
            type          = "AverageValue"
            average_value = metric.value
          }
        }
      }
    }
  }
}
