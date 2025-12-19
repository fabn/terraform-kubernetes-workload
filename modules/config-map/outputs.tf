output "config_map" {
  description = "The kubernetes_config_map_v1 resource"
  value       = kubernetes_config_map_v1.this
}

output "name" {
  description = "The generated name of the ConfigMap (includes content hash)"
  value       = kubernetes_config_map_v1.this.metadata[0].name
}

output "sha" {
  description = "The content hash used in the name"
  value       = local.sha
}
