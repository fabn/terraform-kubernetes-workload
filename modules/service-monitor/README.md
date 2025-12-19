# ServiceMonitor Submodule

Standalone Prometheus Operator ServiceMonitor module for Kubernetes.

## Usage

```hcl
module "service_monitor" {
  source = "fabn/workload/kubernetes//modules/service-monitor"

  namespace = "production"
  name      = "my-app"

  selector = {
    "app.kubernetes.io/name" = "my-app"
  }

  endpoints = [{
    port     = "metrics"
    path     = "/metrics"
    interval = "30s"
  }]

  labels = {
    "app.kubernetes.io/name" = "my-app"
  }
}
```

## Requirements

This module creates a ServiceMonitor CRD resource, which requires the Prometheus Operator to be installed in your cluster.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `namespace` | Kubernetes namespace | `string` | yes |
| `name` | ServiceMonitor resource name | `string` | yes |
| `selector` | Label selector for matching services | `map(string)` | yes |
| `labels` | Labels for the ServiceMonitor | `map(string)` | no |
| `endpoints` | List of endpoint configurations | `list(object)` | no |

### Endpoints Object

```hcl
endpoints = [{
  port     = "metrics"   # Named port to scrape
  path     = "/metrics"  # Path to scrape (default: /metrics)
  interval = "30s"       # Scrape interval (default: 30s)
}]
```

## Outputs

| Name | Description |
|------|-------------|
| `manifest` | The ServiceMonitor manifest |
| `name` | The name of the ServiceMonitor |
