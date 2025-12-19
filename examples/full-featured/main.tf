# =============================================================================
# Full Featured Example
# =============================================================================
# This example shows all features enabled: HPA, PDB, ServiceMonitor, volumes, etc.

module "api" {
  source = "../.."

  namespace        = "production"
  name             = "my-api"
  image            = "my-registry/api:v1.0.0"
  create_namespace = false

  # Container configuration
  replicas             = 3
  cpu_requests         = "200m"
  memory_requests      = "512Mi"
  memory_limits        = "1Gi"
  service_account_name = "my-api-sa"
  image_pull_secrets   = "registry-credentials"

  # Port configuration
  ports = {
    http    = 8080
    metrics = 9090
  }

  # Health probes
  http_probe_path    = "/health"
  startup_probe_path = "/health/startup"
  probe_port         = "http"

  # Environment variables
  envs = {
    RAILS_ENV    = "production"
    LOG_LEVEL    = "info"
    METRICS_PORT = "9090"
  }

  # ConfigMap and Secret references
  config_map_refs = ["app-config"]
  secret_refs     = ["app-secrets"]

  # Individual env values from secrets
  env_value_from = [
    {
      name = "DATABASE_URL"
      secret_key_ref = {
        name = "database-credentials"
        key  = "url"
      }
    }
  ]

  # Volumes
  volumes = [
    {
      name       = "config"
      mount_path = "/app/config"
      config_map = "app-config-files"
      read_only  = true
    },
    {
      name       = "secrets"
      mount_path = "/app/secrets"
      secret     = "app-secret-files"
      read_only  = true
      mode       = "0400"
    }
  ]

  # EmptyDir for temporary storage
  empty_dirs = ["/tmp", "/app/cache"]

  # Ingress configuration
  ingress_hostnames   = ["api.example.com"]
  ingress_class_name  = "nginx"
  ingress_tls_enabled = true
  ingress_annotations = {
    "nginx.ingress.kubernetes.io/proxy-body-size"    = "100m"
    "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
  }

  # Pod scheduling
  anti_affinity = "hard"

  # Init container for database migrations
  init_container = {
    command = ["bin/rails", "db:migrate"]
  }

  # HPA configuration
  hpa_enabled = true
  hpa_config = {
    min_replicas = 3
    max_replicas = 10
    metrics = {
      cpu_utilization    = 70
      memory_utilization = 80
    }
  }

  # PDB configuration
  pdb_enabled = true
  pdb_config = {
    min_available = "50%"
  }

  # ServiceMonitor for Prometheus
  service_monitor_enabled = true
  service_monitor_config = {
    port     = "metrics"
    path     = "/metrics"
    interval = "15s"
  }

  # Labels
  labels = {
    team        = "platform"
    environment = "production"
  }
}
