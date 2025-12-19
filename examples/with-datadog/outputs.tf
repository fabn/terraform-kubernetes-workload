output "deployment_name" {
  description = "The name of the deployment"
  value       = module.api.name
}

output "pod_labels" {
  description = "Labels applied to pods (includes Datadog labels)"
  value       = module.api.pod_labels
}

output "pod_annotations" {
  description = "Annotations applied to pods (includes Datadog annotations)"
  value       = module.api.pod_annotations
}
