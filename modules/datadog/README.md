# Datadog Submodule

Helper module for generating Datadog pod labels and annotations.

## Features

- **Unified Service Tagging (UST)**: Standard labels for service catalog and APM correlation
- **Admission Controller**: Pod label for automatic environment variable injection
- **Log Collection**: Annotations for Datadog log collection configuration
- **Autodiscovery Checks**: Annotations for built-in and custom Datadog checks

## Usage

```hcl
module "datadog" {
  source = "fabn/workload/kubernetes//modules/datadog"

  container_name = "my-app"

  # Unified Service Tagging
  ust_tags = {
    service = "my-api"
    env     = "production"
    version = "v1.0.0"
    team    = "platform"
  }

  # Log configuration
  log_config = {
    source  = "ruby"
    service = "my-api"
    exclude = ["health", "ready"]
  }

  # Admission Controller (enabled by default)
  admission_controller_enabled = true

  # Built-in check
  check_id = "postgres"

  # Or custom checks
  # checks = {
  #   my_check = { host = "%%host%%", port = 9090 }
  # }
}

# Use outputs in your deployment
resource "kubernetes_deployment_v1" "app" {
  # ...
  spec {
    template {
      metadata {
        labels      = module.datadog.pod_labels
        annotations = module.datadog.pod_annotations
      }
    }
  }
}
```

## Important Notes

### Admission Controller Label

The `admission.datadoghq.com/enabled: "true"` is a **POD LABEL**, not an annotation. This is critical for the Datadog Admission Controller to properly inject environment variables.

Reference: https://docs.datadoghq.com/containers/cluster_agent/admission_controller/

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `container_name` | Container name for annotations | `string` | required |
| `admission_controller_enabled` | Enable admission controller label | `bool` | `true` |
| `ust_tags` | Unified Service Tagging config | `object` | `{}` |
| `log_config` | Log collection configuration | `object` | `{}` |
| `checks` | Custom autodiscovery checks | `map(any)` | `{}` |
| `check_id` | Built-in check ID (e.g., postgres) | `string` | `null` |

### UST Tags Object

```hcl
ust_tags = {
  service = "my-api"       # Service name
  env     = "production"   # Environment
  version = "v1.0.0"       # Version
  team    = "platform"     # Team name
}
```

### Log Config Object

```hcl
log_config = {
  source  = "ruby"              # Log source
  service = "my-api"            # Service name
  exclude = ["health", "ready"] # Patterns to exclude
}
```

## Outputs

| Name | Description |
|------|-------------|
| `pod_labels` | Complete pod labels (UST + admission controller) |
| `pod_annotations` | Complete pod annotations (logs + checks) |
| `ust_labels` | UST labels only |
| `admission_labels` | Admission controller label only |
| `log_annotations` | Log collection annotations only |
| `check_annotations` | Autodiscovery check annotations only |
