output "deployment_name" {
  description = "The name of the deployment"
  value       = module.web.name
}

output "service_name" {
  description = "The name of the service"
  value       = module.web.service_name
}

output "ingress" {
  description = "The ingress resource"
  value       = module.web.ingress
}

output "hostnames" {
  description = "The hostnames configured for ingress"
  value       = ["app.example.com", "www.example.com"]
}
