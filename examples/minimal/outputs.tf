output "deployment_name" {
  description = "The name of the deployment"
  value       = module.app.name
}

output "namespace" {
  description = "The namespace of the deployment"
  value       = module.app.namespace
}
