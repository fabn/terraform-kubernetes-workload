# =============================================================================
# Pod Disruption Budget
# =============================================================================

locals {
  # Use min_available if set, otherwise default to max_unavailable = "1"
  use_min_available = var.min_available != null
}

resource "kubernetes_pod_disruption_budget_v1" "this" {
  metadata {
    namespace = var.namespace
    name      = var.name
    labels    = var.labels
  }

  spec {
    min_available   = local.use_min_available ? var.min_available : null
    max_unavailable = local.use_min_available ? null : coalesce(var.max_unavailable, "1")

    selector {
      match_labels = var.selector
    }
  }
}
