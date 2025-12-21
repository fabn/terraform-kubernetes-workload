output "name" {
  description = "The name of the deployment"
  value       = var.name
}

output "namespace" {
  description = "The namespace of the deployment"
  value       = local.namespace
}

output "deployment" {
  description = "The kubernetes_deployment_v1 resource"
  value       = kubernetes_deployment_v1.this
}

output "service" {
  description = "The kubernetes_service_v1 resource (null if not created)"
  value       = one(kubernetes_service_v1.this)
}

output "service_name" {
  description = "The name of the service (null if not created)"
  value       = try(kubernetes_service_v1.this[0].metadata[0].name, null)
}

output "ingress" {
  description = "The kubernetes_ingress_v1 resource (null if not created)"
  value       = one(kubernetes_ingress_v1.this)
}

output "labels" {
  description = "The labels applied to the deployment"
  value       = local.labels
}

output "selector_labels" {
  description = "The selector labels for targeting this deployment's pods"
  value       = local.selector_labels
}

output "pod_labels" {
  description = "The labels applied to pod template"
  value       = local.pod_labels
}

output "pod_annotations" {
  description = "The annotations applied to pod template"
  value       = local.pod_annotations
}

output "hpa" {
  description = "The HPA resource (null if not created)"
  value       = var.hpa_enabled && var.hpa_config != null ? module.hpa[0].hpa : null
}

output "pdb" {
  description = "The PDB resource (null if not created)"
  value       = var.pdb_enabled ? module.pdb[0].pdb : null
}

output "service_monitor" {
  description = "The ServiceMonitor manifest (null if not created)"
  value       = var.service_monitor_enabled && length(var.ports) > 0 ? module.service_monitor[0].manifest : null
}

output "sops_secrets" {
  description = "Map of SOPS secrets created (key => secret name)"
  value       = { for k, v in module.sops_secret : k => v.name }
}
