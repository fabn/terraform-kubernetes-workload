output "secret" {
  description = "The kubernetes_secret_v1 resource"
  value       = kubernetes_secret_v1.this
  sensitive   = true
}

output "name" {
  description = "The generated name of the Secret (includes content hash)"
  value       = nonsensitive(kubernetes_secret_v1.this.metadata[0].name)
}

output "sha" {
  description = "The content hash used in the name (not sensitive - only contains hash, not actual content)"
  value       = nonsensitive(local.sha)
}
