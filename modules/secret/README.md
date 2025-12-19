# Secret Submodule

Kubernetes Secret with content-hash naming for automatic deployment rollouts.

## Features

- **Content-hash naming**: Secret name includes SHA of content (`{prefix}-{sha8}`)
- **Automatic rollouts**: When content changes, name changes, triggering deployment updates
- **Sensitive handling**: Data marked as sensitive in Terraform state
- **Multiple types**: Support for Opaque, TLS, Docker registry, and other secret types

## Usage

```hcl
module "app_secrets" {
  source = "fabn/workload/kubernetes//modules/secret"

  namespace   = "production"
  name_prefix = "my-app"

  data = {
    "database-url"    = "postgres://user:pass@host:5432/db"
    "api-key"         = var.api_key
    "encryption-key"  = var.encryption_key
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

  # Reference by generated name - deployment will rollout when secrets change
  secret_refs = [module.app_secrets.name]
}
```

### Docker Registry Secret

```hcl
module "registry_secret" {
  source = "fabn/workload/kubernetes//modules/secret"

  namespace   = "production"
  name_prefix = "registry-creds"
  type        = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.example.com" = {
          username = var.registry_user
          password = var.registry_pass
          auth     = base64encode("${var.registry_user}:${var.registry_pass}")
        }
      }
    })
  }
}
```

### TLS Secret

```hcl
module "tls_secret" {
  source = "fabn/workload/kubernetes//modules/secret"

  namespace   = "production"
  name_prefix = "my-app-tls"
  type        = "kubernetes.io/tls"

  data = {
    "tls.crt" = file("certs/tls.crt")
    "tls.key" = file("certs/tls.key")
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `namespace` | Kubernetes namespace | `string` | yes |
| `name_prefix` | Prefix for Secret name | `string` | yes |
| `type` | Secret type (Opaque, kubernetes.io/tls, etc.) | `string` | no |
| `data` | Secret data (auto base64 encoded) | `map(string)` | no |
| `binary_data` | Binary data (already base64 encoded) | `map(string)` | no |
| `labels` | Labels for the Secret | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| `secret` | The kubernetes_secret_v1 resource (sensitive) |
| `name` | Generated name including content hash |
| `sha` | The content hash (first 8 chars of SHA256) |

## How It Works

The Secret name is generated as `{name_prefix}-{sha8}` where `sha8` is the first 8 characters of the SHA256 hash of the combined `data` and `binary_data`.

When the content changes:
1. The SHA changes
2. The Secret name changes
3. Any Deployment referencing this Secret detects the name change
4. Kubernetes triggers a rolling update

This pattern ensures secret changes are always deployed without manual intervention.

## Security Notes

- The `data` and `binary_data` variables are marked as `sensitive = true`
- The `secret` output is marked as sensitive
- The `name` output uses `nonsensitive()` since it only contains the generated name, not secret content
- Secret values are stored in Terraform state - ensure your state backend is properly secured
