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
  # https://docs.datadoghq.com/agent/logs/advanced_log_collection/?tab=kubernetes#filter-logs

  # Build exclusion rules using log_processing_rules format
  exclusion_rules = [
    for pattern in coalesce(var.log_config.exclude, []) : {
      type    = "exclude_at_match"
      name    = "exclude-${replace(pattern, "/\\W+/", "-")}"
      pattern = pattern
    }
  ]

  # Build log configuration object
  log_config_object = merge(
    { for k, v in {
      source  = var.log_config.source
      service = var.log_config.service
    } : k => v if v != null },
    length(local.exclusion_rules) > 0 ? {
      log_processing_rules = local.exclusion_rules
    } : {}
  )

  log_annotations = var.log_config.enabled ? (
    length(keys(local.log_config_object)) > 0 ? {
      "ad.datadoghq.com/${var.container_name}.logs" = jsonencode([local.log_config_object])
    } : {}
  ) : local.logs_exclude_annotations

  # When log collection is disabled, exclude the container with the dedicated
  # annotation (Datadog Agent v7.45+) instead of a catch-all exclude_at_match
  # rule, so its lines never enter the Agent's processing pipeline. Metrics
  # collection is not affected. A .logs annotation is not emitted in this case.
  # https://docs.datadoghq.com/containers/guide/container-discovery-management/#pod-exclude-configuration
  logs_exclude_annotations = {
    "ad.datadoghq.com/${var.container_name}.logs_exclude" = "true"
  }

  # Autodiscovery check annotations (AD v2 format)
  # https://docs.datadoghq.com/containers/kubernetes/integrations/
  check_annotations = var.check_id != null || length(var.checks) > 0 ? {
    "ad.datadoghq.com/${var.container_name}.checks" = jsonencode(
      var.check_id != null ? {
        (var.check_id) = {
          instances = [{}]
        }
        } : {
        for name, config in var.checks : name => merge(
          { instances = config.instances },
          length(coalesce(config.init_config, {})) > 0 ? { init_config = config.init_config } : {}
        )
      }
    )
  } : {}
}
