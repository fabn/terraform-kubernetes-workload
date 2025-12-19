output "config_map_name" {
  description = "The generated name of the ConfigMap"
  value       = module.app_config.name
}

output "content_sha" {
  description = "The content hash used in the name"
  value       = module.app_config.sha
}
