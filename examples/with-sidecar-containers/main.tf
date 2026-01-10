# =============================================================================
# Sidecar Containers Example
# =============================================================================
# This example demonstrates how to add sidecar containers alongside the main
# application container. Sidecars are useful for logging, monitoring, proxies,
# and other supporting functions.

module "app" {
  source = "../.."

  namespace = "default"
  name      = "app-with-sidecars"
  image     = "nginx:latest"

  # Main container configuration
  ports = {
    http = 80
  }

  # Sidecar containers
  # Each sidecar inherits environment variables, volume mounts, and working directory
  # from the main container configuration
  sidecar_containers = [
    {
      name    = "logging-sidecar"
      image   = "fluent/fluentd:latest"
      command = ["fluentd"]
      args    = ["-c", "/fluentd/etc/fluent.conf", "-v"]
    },
    {
      name  = "metrics-exporter"
      image = "nginx/nginx-prometheus-exporter:latest"
      args  = ["-nginx.scrape-uri=http://localhost:80/stub_status"]
    },
    {
      # Sidecar using the same image as the main container
      name    = "helper"
      command = ["/bin/sh"]
      args    = ["-c", "while true; do echo 'Helper running...'; sleep 30; done"]
    }
  ]

  # Shared environment variables (inherited by all containers)
  envs = {
    APP_ENV   = "production"
    LOG_LEVEL = "info"
  }

  # Shared volumes (inherited by all containers)
  volumes = [
    {
      name       = "shared-logs"
      mount_path = "/var/log"
      config_map = "log-config"
    }
  ]
}
