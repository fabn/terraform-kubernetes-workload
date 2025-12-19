output "manifest" {
  description = "The ServiceMonitor manifest"
  value       = kubernetes_manifest.this.manifest
}

output "name" {
  description = "The name of the ServiceMonitor"
  value       = var.name
}
