# =============================================================================
# Standalone Secret Example
# =============================================================================
# This example shows how to use the secret submodule independently.

variable "database_password" {
  description = "Database password"
  type        = string
  default     = "example-password" # In real usage, use a sensitive variable
  sensitive   = true
}

variable "api_key" {
  description = "External API key"
  type        = string
  default     = "example-api-key" # In real usage, use a sensitive variable
  sensitive   = true
}

module "app_secrets" {
  source = "../../modules/secret"

  namespace   = "default"
  name_prefix = "my-app-secrets"

  data = {
    "DATABASE_URL"   = "postgres://app:${var.database_password}@postgres:5432/mydb"
    "REDIS_URL"      = "redis://redis:6379/0"
    "API_KEY"        = var.api_key
    "ENCRYPTION_KEY" = "32-byte-encryption-key-here!!!!" # Example only
    "SESSION_SECRET" = "super-secret-session-key"
  }

  labels = {
    "app.kubernetes.io/name"      = "my-app"
    "app.kubernetes.io/component" = "secrets"
  }
}
