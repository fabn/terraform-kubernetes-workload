output "deployment" {
  description = "The deployment resource"
  value       = module.api.deployment
}

output "service_name" {
  description = "The name of the service"
  value       = module.api.service_name
}

output "ingress" {
  description = "The ingress resource"
  value       = module.api.ingress
}

output "hpa" {
  description = "The HPA resource"
  value       = module.api.hpa
}

output "pdb" {
  description = "The PDB resource"
  value       = module.api.pdb
}

output "service_monitor" {
  description = "The ServiceMonitor manifest"
  value       = module.api.service_monitor
}

output "labels" {
  description = "Labels applied to resources"
  value       = module.api.labels
}
