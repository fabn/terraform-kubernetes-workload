# ConfigMap Submodule

Kubernetes ConfigMap with content-hash naming for automatic deployment rollouts.

## Features

- **Content-hash naming**: ConfigMap name includes SHA of content (`{prefix}-{sha8}`)
- **Automatic rollouts**: When content changes, name changes, triggering deployment updates
- **Binary data support**: Store both text and binary data

## Usage

```hcl
module "app_config" {
  source = "fabn/workload/kubernetes//modules/config-map"

  namespace   = "production"
  name_prefix = "my-app"

  data = {
    "config.yaml"    = file("config.yaml")
    "settings.json"  = jsonencode({ debug = false, log_level = "info" })
    "DATABASE_HOST"  = "postgres.db.svc.cluster.local"
  }

  labels = {
    "app.kubernetes.io/name" = "my-app"
  }
}

# Use with workload module
module "app" {
  source = "fabn/workload/kubernetes"

  namespace = "production"
  name      = "my-app"
  image     = "my-registry/app:v1.0.0"

  # Reference by generated name - deployment will rollout when config changes
  config_map_refs = [module.app_config.name]
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `namespace` | Kubernetes namespace | `string` | yes |
| `name_prefix` | Prefix for ConfigMap name | `string` | yes |
| `data` | Key-value data to store | `map(string)` | no |
| `binary_data` | Binary data (base64 encoded) | `map(string)` | no |
| `labels` | Labels for the ConfigMap | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| `config_map` | The kubernetes_config_map_v1 resource |
| `name` | Generated name including content hash |
| `sha` | The content hash (first 8 chars of SHA256) |

## How It Works

The ConfigMap name is generated as `{name_prefix}-{sha8}` where `sha8` is the first 8 characters of the SHA256 hash of the combined `data` and `binary_data`.

When the content changes:
1. The SHA changes
2. The ConfigMap name changes
3. Any Deployment referencing this ConfigMap detects the name change
4. Kubernetes triggers a rolling update

This pattern ensures configuration changes are always deployed without manual intervention.
