output "deployment_name" {
  description = "The name of the deployment"
  value       = module.api.name
}

output "service_name" {
  description = "The name of the service"
  value       = module.api.service_name
}

output "namespace" {
  description = "The namespace of the deployment"
  value       = module.api.namespace
}
