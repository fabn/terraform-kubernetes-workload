# Terraform Kubernetes Workload Module

A comprehensive Terraform module for deploying Kubernetes workloads with support for Deployment, Service, Ingress, HPA, PDB, ServiceMonitor, and Datadog integration.

## Features

- **Deployment**: Full Kubernetes deployment with configurable replicas, resources, probes, volumes, and init containers
- **Service**: Optional ClusterIP/LoadBalancer/NodePort service creation
- **Ingress**: Optional ingress with TLS, ACME, and canary deployment support
- **HPA**: Horizontal Pod Autoscaler with CPU, memory, and custom metrics
- **PDB**: Pod Disruption Budget for high availability
- **ServiceMonitor**: Prometheus Operator integration for metrics collection
- **Datadog**: Unified Service Tagging, logging, and admission controller integration
- **ConfigMap**: Standalone ConfigMap with content-hash naming for automatic rollouts
- **Secret**: Standalone Secret with content-hash naming for automatic rollouts

## Usage

### Minimal Example

```hcl
module "app" {
  source  = "fabn/workload/kubernetes"
  version = "~> 1.0"

  namespace = "default"
  name      = "my-app"
  image     = "nginx:latest"
}
```

### With Service and Ingress

```hcl
module "api" {
  source  = "fabn/workload/kubernetes"
  version = "~> 1.0"

  namespace = "production"
  name      = "my-api"
  image     = "my-registry/api:v1.0.0"

  # Resource configuration
  replicas        = 3
  cpu_requests    = "200m"
  memory_requests = "512Mi"
  memory_limits   = "1Gi"

  # Ports
  ports = {
    http    = 8080
    metrics = 9090
  }

  # Health probes
  http_probe_path = "/health"

  # Ingress
  ingress_hostnames   = ["api.example.com"]
  ingress_class_name  = "nginx"
  ingress_tls_enabled = true

  # Pod scheduling
  anti_affinity = "soft"
}
```

### With Datadog Integration

```hcl
module "api" {
  source  = "fabn/workload/kubernetes"
  version = "~> 1.0"

  namespace = "production"
  name      = "my-api"
  image     = "my-registry/api:v1.0.0"

  ports = { http = 8080 }

  # Datadog integration
  datadog_enabled = true
  datadog_ust_tags = {
    service = "my-api"
    env     = "production"
    version = "v1.0.0"
  }
  datadog_log_config = {
    source  = "ruby"
    service = "my-api"
  }
  # Admission controller label is enabled by default
}
```

### Full Featured

```hcl
module "api" {
  source  = "fabn/workload/kubernetes"
  version = "~> 1.0"

  namespace = "production"
  name      = "my-api"
  image     = "my-registry/api:v1.0.0"

  # Deployment
  replicas             = 3
  cpu_requests         = "200m"
  memory_requests      = "512Mi"
  service_account_name = "my-api-sa"

  # Ports
  ports = { http = 8080, metrics = 9090 }

  # Probes
  http_probe_path    = "/health"
  startup_probe_path = "/health/startup"

  # Environment
  envs            = { RAILS_ENV = "production" }
  config_map_refs = ["app-config"]
  secret_refs     = ["app-secrets"]

  # Volumes
  volumes = [{
    name       = "config"
    mount_path = "/app/config"
    config_map = "app-config"
  }]

  # Ingress
  ingress_hostnames = ["api.example.com"]

  # Init container for migrations
  init_container = {
    command = ["bin/rails", "db:migrate"]
  }

  # HPA
  hpa_enabled = true
  hpa_config = {
    min_replicas = 3
    max_replicas = 10
    metrics = {
      cpu_utilization = 70
    }
  }

  # PDB
  pdb_enabled = true
  pdb_config = {
    min_available = "50%"
  }

  # ServiceMonitor
  service_monitor_enabled = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| kubernetes | >= 2.25.0 |

## Inputs

### Required

| Name | Description | Type |
|------|-------------|------|
| `namespace` | Kubernetes namespace for the deployment | `string` |
| `name` | Name for the deployment and associated resources | `string` |
| `image` | Docker image to deploy | `string` |

### Deployment Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `replicas` | Number of pod replicas | `number` | `1` |
| `create_namespace` | Create the namespace if it doesn't exist | `bool` | `false` |
| `command` | Container command | `list(string)` | `[]` |
| `args` | Container arguments | `list(string)` | `[]` |
| `working_dir` | Container working directory | `string` | `null` |
| `image_pull_secrets` | Image pull secret name | `string` | `null` |
| `service_account_name` | Service account name | `string` | `null` |

### Resources

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `cpu_requests` | CPU resource request | `string` | `null` |
| `memory_requests` | Memory resource request | `string` | `null` |
| `memory_limits` | Memory resource limit | `string` | `null` |

### Networking

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ports` | Map of port names to port numbers | `map(number)` | `{}` |
| `service_type` | Service type (null to skip) | `string` | `"ClusterIP"` |

### Ingress

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ingress_hostnames` | Hostnames for ingress rules | `list(string)` | `[]` |
| `ingress_annotations` | Additional ingress annotations | `map(string)` | `{}` |
| `ingress_tls_enabled` | Enable TLS | `bool` | `true` |
| `ingress_tls_secret_name` | TLS secret name | `string` | `null` |
| `ingress_class_name` | Ingress class name | `string` | `null` |
| `ingress_acme_enabled` | Enable ACME annotation | `bool` | `true` |

### Canary Deployment

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `canary` | Canary deployment configuration | `object` | `{ enabled = false }` |

### Environment Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `envs` | Plain environment variables | `map(string)` | `{}` |
| `config_map_refs` | ConfigMap names for env | `list(string)` | `[]` |
| `secret_refs` | Secret names for env | `list(string)` | `[]` |
| `env_from` | Advanced envFrom with prefix | `list(object)` | `[]` |
| `env_value_from` | Env from secret/configmap keys | `list(object)` | `[]` |

### Volumes

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `volumes` | Volume definitions | `list(object)` | `[]` |
| `empty_dirs` | EmptyDir volume paths | `list(string)` | `[]` |

### Health Probes

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `http_probe_path` | HTTP path for probes | `string` | `null` |
| `startup_probe_path` | Startup probe path | `string` | `null` |
| `probe_port` | Named port for probes | `string` | `"http"` |

### Pod Scheduling

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `anti_affinity` | Anti-affinity strategy (soft/hard/null) | `string` | `"soft"` |

### Labels and Annotations

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `labels` | Additional labels | `map(string)` | `{}` |
| `pod_annotations` | Pod annotations | `map(string)` | `{}` |
| `deployment_annotations` | Deployment annotations | `map(string)` | `{}` |

### Init Container

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `init_container` | Init container configuration | `object` | `null` |

### Optional Features

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `hpa_enabled` | Enable HPA | `bool` | `false` |
| `hpa_config` | HPA configuration | `object` | `null` |
| `pdb_enabled` | Enable PDB | `bool` | `false` |
| `pdb_config` | PDB configuration | `object` | `null` |
| `service_monitor_enabled` | Enable ServiceMonitor | `bool` | `false` |
| `service_monitor_config` | ServiceMonitor configuration | `object` | `null` |

### Datadog Integration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `datadog_enabled` | Enable Datadog integration | `bool` | `false` |
| `datadog_ust_tags` | Unified Service Tagging | `object` | `{}` |
| `datadog_log_config` | Log collection config | `object` | `{}` |
| `datadog_checks` | Autodiscovery checks | `map(any)` | `{}` |
| `datadog_check_id` | Built-in check ID | `string` | `null` |
| `datadog_admission_controller` | Enable admission controller label | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `name` | The name of the deployment |
| `namespace` | The namespace of the deployment |
| `deployment` | The kubernetes_deployment_v1 resource |
| `service` | The kubernetes_service_v1 resource |
| `service_name` | The name of the service |
| `ingress` | The kubernetes_ingress_v1 resource |
| `labels` | Labels applied to the deployment |
| `selector_labels` | Selector labels for targeting pods |
| `pod_labels` | Labels applied to pod template |
| `pod_annotations` | Annotations applied to pod template |
| `hpa` | The HPA resource |
| `pdb` | The PDB resource |
| `service_monitor` | The ServiceMonitor manifest |

## Standalone Submodules

The module includes standalone submodules that can be used independently:

### HPA Module

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
    cpu_utilization = 70
  }
}
```

### PDB Module

```hcl
module "pdb" {
  source = "fabn/workload/kubernetes//modules/pdb"

  namespace = "production"
  name      = "my-app-pdb"

  selector = {
    "app.kubernetes.io/name" = "my-app"
  }

  min_available = "50%"
}
```

### ConfigMap Module

ConfigMap with content-hash naming - when content changes, the name changes, triggering deployment rollouts.

```hcl
module "app_config" {
  source = "fabn/workload/kubernetes//modules/config-map"

  namespace   = "production"
  name_prefix = "my-app"

  data = {
    "config.yaml" = file("config.yaml")
    "DATABASE_HOST" = "postgres.db.svc.cluster.local"
  }
}

# Use with workload - deployment will rollout when config changes
module "app" {
  source = "fabn/workload/kubernetes"

  namespace       = "production"
  name            = "my-app"
  image           = "my-registry/app:v1.0.0"
  config_map_refs = [module.app_config.name]
}
```

### Secret Module

Secret with content-hash naming - when content changes, the name changes, triggering deployment rollouts.

```hcl
module "app_secrets" {
  source = "fabn/workload/kubernetes//modules/secret"

  namespace   = "production"
  name_prefix = "my-app"

  data = {
    "DATABASE_URL" = var.database_url
    "API_KEY"      = var.api_key
  }
}

# Use with workload - deployment will rollout when secrets change
module "app" {
  source = "fabn/workload/kubernetes"

  namespace   = "production"
  name        = "my-app"
  image       = "my-registry/app:v1.0.0"
  secret_refs = [module.app_secrets.name]
}
```

## License

Apache 2.0 - See [LICENSE](LICENSE) for more information.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
