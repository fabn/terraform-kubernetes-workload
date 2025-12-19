# =============================================================================
# With Datadog Example
# =============================================================================
# This example shows Datadog integration with UST tags, logging, and
# automatic env injection via admission controller.

module "api" {
  source = "../.."

  namespace = "production"
  name      = "my-api"
  image     = "my-registry/api:v1.0.0"

  # Container configuration
  replicas        = 2
  cpu_requests    = "200m"
  memory_requests = "512Mi"

  # Port configuration
  ports = {
    http    = 8080
    metrics = 9090
  }

  # Health probes
  http_probe_path = "/health"

  # Datadog integration
  datadog_enabled = true

  # Unified Service Tagging (UST)
  # These labels are used for service catalog and APM correlation
  datadog_ust_tags = {
    service = "my-api"
    env     = "production"
    version = "v1.0.0"
    team    = "platform"
  }

  # Log collection configuration
  # exclude: patterns to filter out from logs (uses log_processing_rules with exclude_at_match)
  # Useful for health checks, readiness probes, or noisy endpoints
  datadog_log_config = {
    source  = "ruby"
    service = "my-api"
    exclude = ["/health", "/readiness"]
  }

  # Admission Controller (enabled by default when datadog_enabled = true)
  # This adds the "admission.datadoghq.com/enabled: true" LABEL to pods
  # which triggers automatic injection of DD_* environment variables
  datadog_admission_controller = true

  # Custom Datadog checks (optional)
  # datadog_checks = {
  #   my_custom_check = {
  #     host = "%%host%%"
  #     port = 9090
  #   }
  # }

  # Or use a built-in check ID
  # datadog_check_id = "postgres"
}
