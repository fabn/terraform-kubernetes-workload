# HPA Submodule

Standalone Horizontal Pod Autoscaler (HPA) module for Kubernetes.

## Usage

```hcl
module "hpa" {
  source = "fabn/workload/kubernetes//modules/hpa"

  namespace = "production"
  name      = "my-app-hpa"

  target_ref = {
    api_version = "apps/v1"
    kind        = "Deployment"
    name        = "my-app"
  }

  min_replicas = 2
  max_replicas = 10

  metrics = {
    cpu_utilization    = 70
    memory_utilization = 80
  }

  labels = {
    "app.kubernetes.io/name" = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `namespace` | Kubernetes namespace | `string` | yes |
| `name` | HPA resource name | `string` | yes |
| `target_ref` | Reference to scalable resource | `object` | yes |
| `max_replicas` | Maximum replicas | `number` | yes |
| `min_replicas` | Minimum replicas | `number` | no (default: 1) |
| `labels` | Labels for the HPA | `map(string)` | no |
| `metrics` | HPA metrics configuration | `object` | no |

### Metrics Object

```hcl
metrics = {
  cpu_utilization    = 70          # Target CPU utilization %
  memory_utilization = 80          # Target memory utilization %
  pod_metrics = {                  # Custom pod metrics
    "requests_per_second" = "100"
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `hpa` | The kubernetes_horizontal_pod_autoscaler_v2 resource |
| `name` | The name of the HPA |
