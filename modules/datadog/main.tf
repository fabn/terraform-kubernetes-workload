# =============================================================================
# Datadog Integration Helper
# =============================================================================
# This module generates pod labels and annotations for Datadog integration.
# It supports:
# - Unified Service Tagging (UST) labels
# - Admission Controller label (for automatic env injection)
# - Log collection configuration
# - Autodiscovery checks (both built-in and custom)
#
# Reference: https://docs.datadoghq.com/containers/kubernetes/

locals {
  # Unified Service Tagging labels
  # https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging/
  ust_labels = {
    for key, value in {
      "tags.datadoghq.com/service" = var.ust_tags.service
      "tags.datadoghq.com/env"     = var.ust_tags.env
      "tags.datadoghq.com/version" = var.ust_tags.version
      "team"                       = var.ust_tags.team
    } : key => value if value != null
  }

  # Admission Controller label
  # NOTE: This is a POD LABEL, not an annotation!
  # https://docs.datadoghq.com/containers/cluster_agent/admission_controller/
  admission_labels = var.admission_controller_enabled ? {
    "admission.datadoghq.com/enabled" = "true"
  } : {}

  # Log collection annotations
  # https://docs.datadoghq.com/containers/kubernetes/log/
  log_config_entries = compact([
    var.log_config.source != null ? "\"source\": \"${var.log_config.source}\"" : null,
    var.log_config.service != null ? "\"service\": \"${var.log_config.service}\"" : null,
    length(var.log_config.exclude) > 0 ? "\"exclude_at_match\": \"${join("|", var.log_config.exclude)}\"" : null
  ])

  log_annotations = length(local.log_config_entries) > 0 ? {
    "ad.datadoghq.com/${var.container_name}.logs" = "[{${join(", ", local.log_config_entries)}}]"
  } : {}

  # Autodiscovery check annotations
  # https://docs.datadoghq.com/containers/kubernetes/integrations/
  check_annotations = var.check_id != null || length(var.checks) > 0 ? {
    "ad.datadoghq.com/${var.container_name}.check_names"  = jsonencode(var.check_id != null ? [var.check_id] : keys(var.checks))
    "ad.datadoghq.com/${var.container_name}.init_configs" = jsonencode(var.check_id != null ? [{}] : [for _ in var.checks : {}])
    "ad.datadoghq.com/${var.container_name}.instances"    = jsonencode(var.check_id != null ? [{}] : values(var.checks))
  } : {}
}
