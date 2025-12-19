output "secret_name" {
  description = "The generated name of the Secret"
  value       = module.app_secrets.name
}

output "content_sha" {
  description = "The content hash used in the name"
  value       = module.app_secrets.sha
}
