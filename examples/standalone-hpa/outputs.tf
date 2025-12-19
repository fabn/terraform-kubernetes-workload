output "hpa" {
  description = "The HPA resource"
  value       = module.hpa.hpa
}

output "hpa_name" {
  description = "The name of the HPA"
  value       = module.hpa.name
}
