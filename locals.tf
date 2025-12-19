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
  canary_annotations = var.canary.enabled ? {
    "nginx.ingress.kubernetes.io/canary"        = "true"
    "nginx.ingress.kubernetes.io/canary-weight" = tostring(var.canary.weight)
  } : {}

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
}
