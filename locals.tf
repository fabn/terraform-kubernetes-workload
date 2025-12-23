locals {
  # Namespace resolution
  namespace = var.create_namespace ? kubernetes_namespace_v1.this[0].metadata[0].name : var.namespace

  # Selector labels (used for pod selection)
  selector_labels = {
    "app.kubernetes.io/name" = var.name
  }

  # Standard labels applied to all resources
  standard_labels = merge(local.selector_labels, {
    "app.kubernetes.io/managed-by" = "terraform"
  })

  # Final labels with user additions
  labels = merge(local.standard_labels, var.labels)

  # Canary annotations for nginx ingress controller
  # See: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary
  canary_annotations = var.canary.enabled ? merge(
    {
      "nginx.ingress.kubernetes.io/canary" = "true"
    },
    # Weight-based routing
    var.canary.weight > 0 ? {
      "nginx.ingress.kubernetes.io/canary-weight" = tostring(var.canary.weight)
    } : {},
    var.canary.weight_total != null ? {
      "nginx.ingress.kubernetes.io/canary-weight-total" = tostring(var.canary.weight_total)
    } : {},
    # Header-based routing
    var.canary.header != null ? {
      "nginx.ingress.kubernetes.io/canary-by-header" = var.canary.header
    } : {},
    var.canary.header_value != null ? {
      "nginx.ingress.kubernetes.io/canary-by-header-value" = var.canary.header_value
    } : {},
    var.canary.header_pattern != null ? {
      "nginx.ingress.kubernetes.io/canary-by-header-pattern" = var.canary.header_pattern
    } : {},
    # Cookie-based routing
    var.canary.cookie != null ? {
      "nginx.ingress.kubernetes.io/canary-by-cookie" = var.canary.cookie
    } : {},
  ) : {}

  # ACME TLS annotation
  acme_annotations = var.ingress_acme_enabled && var.ingress_tls_enabled ? {
    "kubernetes.io/tls-acme" = "true"
  } : {}

  # Final ingress annotations
  ingress_annotations = merge(
    var.ingress_annotations,
    local.acme_annotations,
    local.canary_annotations
  )

  # TLS secret name
  tls_secret_name = coalesce(var.ingress_tls_secret_name, "${var.name}-tls-ingress")

  # Datadog integration
  datadog_labels      = var.datadog_enabled ? module.datadog[0].pod_labels : {}
  datadog_annotations = var.datadog_enabled ? module.datadog[0].pod_annotations : {}

  # Final pod labels (selector + datadog)
  pod_labels = merge(local.labels, local.datadog_labels)

  # Final pod annotations
  pod_annotations = merge(
    var.pod_annotations,
    local.datadog_annotations
  )

  # Resource limits/requests
  memory_limit = coalesce(var.memory_limits, var.memory_requests, "1Gi")

  # SOPS files map for for_each (uses basename without extension as key)
  # Handles multiple extensions like .enc.env, .enc.json, .enc.yaml
  sops_files_map = {
    for f in var.sops_files :
    replace(basename(f.source_file), "/\\.(enc\\.)?(json|yaml|yml|env)$/", "") => f
  }

  # Names of SOPS-generated secrets
  sops_secret_names = [for k, v in module.sops_secret : v.name]

  # All secret refs (user-provided + SOPS-generated)
  all_secret_refs = concat(var.secret_refs, local.sops_secret_names)
}
