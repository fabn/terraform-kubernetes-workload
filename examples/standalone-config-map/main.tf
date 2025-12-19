# =============================================================================
# Standalone ConfigMap Example
# =============================================================================
# This example shows how to use the config-map submodule independently.

module "app_config" {
  source = "../../modules/config-map"

  namespace   = "default"
  name_prefix = "my-app-config"

  data = {
    "config.yaml" = <<-EOT
      database:
        host: postgres.db.svc.cluster.local
        port: 5432
      cache:
        host: redis.cache.svc.cluster.local
        port: 6379
      logging:
        level: info
        format: json
    EOT

    "settings.json" = jsonencode({
      feature_flags = {
        new_ui     = true
        dark_mode  = false
        beta_users = ["user1", "user2"]
      }
    })

    # Environment variables style
    "DATABASE_HOST" = "postgres.db.svc.cluster.local"
    "CACHE_HOST"    = "redis.cache.svc.cluster.local"
  }

  labels = {
    "app.kubernetes.io/name"      = "my-app"
    "app.kubernetes.io/component" = "config"
  }
}
