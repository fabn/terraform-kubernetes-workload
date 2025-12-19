# =============================================================================
# ServiceMonitor (Prometheus Operator CRD)
# =============================================================================

# ServiceMonitor is a Prometheus Operator CRD, we use kubernetes_manifest
# to create it as a raw Kubernetes manifest

resource "kubernetes_manifest" "this" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = var.name
      namespace = var.namespace
      labels    = var.labels
    }

    spec = {
      selector = {
        matchLabels = var.selector
      }

      endpoints = [
        for endpoint in var.endpoints : {
          port     = endpoint.port
          path     = endpoint.path
          interval = endpoint.interval
        }
      ]
    }
  }
}
