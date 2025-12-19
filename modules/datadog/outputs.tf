# =============================================================================
# Pod Labels
# =============================================================================
# NOTE: admission.datadoghq.com/enabled is a POD LABEL, not an annotation!
# This is critical for the Datadog Admission Controller to inject environment
# variables automatically.
# Reference: https://docs.datadoghq.com/containers/cluster_agent/admission_controller/

output "pod_labels" {
  description = "Pod labels including UST tags and admission controller label"
  value = merge(
    local.ust_labels,
    local.admission_labels
  )
}

# =============================================================================
# Pod Annotations
# =============================================================================

output "pod_annotations" {
  description = "Pod annotations for logging and autodiscovery checks"
  value = merge(
    local.log_annotations,
    local.check_annotations
  )
}

# =============================================================================
# Individual Outputs
# =============================================================================

output "ust_labels" {
  description = "Unified Service Tagging labels only"
  value       = local.ust_labels
}

output "admission_labels" {
  description = "Admission Controller label only"
  value       = local.admission_labels
}

output "log_annotations" {
  description = "Log collection annotations only"
  value       = local.log_annotations
}

output "check_annotations" {
  description = "Autodiscovery check annotations only"
  value       = local.check_annotations
}
