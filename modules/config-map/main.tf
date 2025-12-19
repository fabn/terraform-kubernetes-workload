# =============================================================================
# ConfigMap with Content-Hash Naming
# =============================================================================
# This module creates a ConfigMap with a content-based hash suffix in the name.
# When the content changes, the name changes, which triggers a rolling update
# of any Deployment referencing this ConfigMap.

locals {
  # Generate SHA from combined data for content-based naming
  sha = substr(sha256(jsonencode(merge(var.data, var.binary_data))), 0, 8)

  # Standard labels
  standard_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Final labels
  labels = merge(local.standard_labels, var.labels)
}

resource "kubernetes_config_map_v1" "this" {
  metadata {
    namespace = var.namespace
    name      = "${var.name_prefix}-${local.sha}"
    labels    = local.labels
  }

  data        = var.data
  binary_data = var.binary_data
}
