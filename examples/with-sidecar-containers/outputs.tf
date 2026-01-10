output "deployment" {
  description = "Kubernetes deployment details"
  value       = module.app.deployment
}

output "service" {
  description = "Kubernetes service details"
  value       = module.app.service
}

output "labels" {
  description = "Standard labels applied to resources"
  value       = module.app.labels
}
