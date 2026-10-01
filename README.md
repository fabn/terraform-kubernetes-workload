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
- **SOPS**: Automatic decryption of SOPS-encrypted files and creation of Kubernetes secrets

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

### Behind an AWS ALB (EKS Auto Mode / AWS Load Balancer Controller)

TLS terminates on the ALB (e.g. with an ACM certificate wired into the
IngressClass), so setting `alb` suppresses in-cluster TLS (`spec.tls`) and the
ACME annotation, and adds the ALB listener/health check annotations instead:

```hcl
module "api" {
  source  = "fabn/workload/kubernetes"
  version = "~> 0.6"

  namespace = "production"
  name      = "my-api"
  image     = "my-registry/api:v1.0.0"
  ports     = { http = 8080 }

  ingress_hostnames  = ["api.example.com"]
  ingress_class_name = "external"

  alb = {
    # Optional: name of the shared (group) ALB. Every Ingress of the group
    # must carry the same value. Only honored at ALB creation time.
    load_balancer_name = "my-cluster-external"
    # Defaults: listen_ports = [{ HTTPS = 443 }], healthcheck_path = "/"
  }
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
    exclude = ["/health", "/ready"]  # Optional: filter noisy endpoints from logs
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

  # Sidecar containers for logging and monitoring
  sidecar_containers = [
    {
      name    = "logging-sidecar"
      image   = "fluent/fluentd:latest"
      command = ["fluentd"]
      args    = ["-c", "/fluentd/etc/fluent.conf"]
    },
    {
      name  = "metrics-exporter"
      image = "nginx/nginx-prometheus-exporter:latest"
      args  = ["-nginx.scrape-uri=http://localhost:80/stub_status"]
      # Sidecar ports are merged into the service
      ports = {
        metrics = 9113
      }
    }
  ]

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

## Image pull policy

The module always renders `imagePullPolicy` explicitly, one container at a
time, derived from that container's image reference:

| Image reference | Policy |
|-----------------|--------|
| `nginx`, `registry.internal:5000/team/api` (no tag) | `Always` |
| `nginx:latest` | `Always` |
| `my-registry/api:v1.0.0` | `IfNotPresent` |
| `my-registry/api@sha256:…` | `IfNotPresent` |

That is the same rule Kubernetes applies, but Kubernetes applies it only as a
*default* — that is, only while the field is empty. Once the API server has
filled it in, the value sticks, and the image can change underneath it:

- a Deployment first created on `:latest` keeps `Always` after moving to a
  pinned tag, re-pulling an immutable image on every pod start;
- one first created on a pinned tag keeps `IfNotPresent` after moving to
  `:latest`, where it can then serve a stale cached image instead of the one
  that was just pushed.

Rendering the policy makes it a function of the current image, recomputed on
every apply, so neither drift survives.

Set `image_pull_policy` to override the derivation for all containers of the
workload — for example `Never` on a local cluster where images are preloaded
into the nodes:

```hcl
module "workload" {
  source  = "fabn/workload/kubernetes"

  name              = "api"
  namespace         = "default"
  image             = "my-registry/api:v1.0.0"
  image_pull_policy = "Never"
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
| `image_pull_policy` | Override `containers[].imagePullPolicy`. When `null` the policy is derived from each container's image reference — `Always` for a mutable one (no tag, or `:latest`), `IfNotPresent` for a pinned tag or digest — and rendered explicitly. See [Image pull policy](#image-pull-policy). | `string` | `null` |
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
| `alb` | AWS ALB mode: adds listener/health check annotations, suppresses in-cluster TLS and ACME | `object` | `null` |

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
| `tcp_probe_port` | Named port for TCP probes (mutually exclusive with the HTTP paths) | `string` | `null` |
| `startup_probe_timeout_seconds` | startupProbe timeoutSeconds (null = k8s default 1) | `number` | `null` |
| `startup_probe_failure_threshold` | startupProbe failureThreshold (null = k8s default 3) | `number` | `null` |
| `probe_timeout_seconds` | liveness/readiness timeoutSeconds (null = k8s default 1) | `number` | `null` |
| `probe_failure_threshold` | liveness/readiness failureThreshold (null = k8s default 3) | `number` | `null` |

### Pod Scheduling

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `anti_affinity` | Anti-affinity strategy (soft/hard/null) | `string` | `"soft"` |
| `node_selector` | Exact-match node selector (label => value) | `map(string)` | `null` |
| `tolerations` | Pod tolerations, e.g. to run on a tainted dedicated node pool (`node_selector` only attracts, it does not tolerate the taint). Rendered into `spec.tolerations` only when non-empty. | `list(object({ key, operator, value, effect, toleration_seconds }))` | `[]` |
| `node_affinity` | Optional node affinity: `required` match expressions (ANDed into one hard term) + `preferred` weighted match expressions. E.g. require spot & non-`t`, prefer `arm64`. | `object({ required = list(...), preferred = list(...) })` | `null` |
| `pod_affinity` | Optional pod affinity (co-location): `required`/`preferred` terms, each a `topology_key` + label selector (`match_labels`/`match_expressions`). | `object({ required = list(...), preferred = list(...) })` | `null` |
| `pod_anti_affinity` | Optional raw pod anti-affinity rules (escape hatch), same shape as `pod_affinity`. Additive to the `anti_affinity` shorthand. | `object({ required = list(...), preferred = list(...) })` | `null` |
| `topology_spread_constraints` | Optional topology spread constraints: list of `{ max_skew, topology_key, when_unsatisfiable, min_domains?, label_selector? }`. `label_selector` defaults to the workload's own pod labels. | `list(object({...}))` | `null` |
| `termination_grace_period_seconds` | `spec.terminationGracePeriodSeconds` (null = k8s default 30). How long the kubelet waits between SIGTERM and SIGKILL, on **every** termination path — autoscaler scale-in, node drain, Spot reclaim, rollout. A queue worker's own shutdown timeout (Sidekiq `-t`, Celery warm shutdown) must fit inside it, or the process is killed while still waiting for its own jobs. Raising it also delays every voluntary drain and node consolidation by the same amount, and on Spot the provider's interruption notice (two minutes on AWS) is a hard ceiling. | `number` | `null` |

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

### Sidecar Containers

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `sidecar_containers` | List of sidecar containers | `list(object)` | `[]` |

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
| `datadog_log_config` | Log collection config (source, service, exclude) | `object` | `{}` |
| `datadog_checks` | Autodiscovery checks (AD v2 format) | `map(object)` | `{}` |
| `datadog_check_id` | Built-in check ID | `string` | `null` |
| `datadog_admission_controller` | Enable admission controller label | `bool` | `true` |

### SOPS Integration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `sops_files` | SOPS encrypted files to decrypt and create as secrets | `list(object)` | `[]` |

Each object in `sops_files` accepts:
- `source_file` (required): Path to the SOPS-encrypted file
- `input_type` (optional): File type (`json`, `yaml`, `dotenv`, `raw`) - auto-detected if omitted

Example:

```hcl
module "app" {
  source = "fabn/workload/kubernetes"

  namespace = "production"
  name      = "my-app"
  image     = "my-registry/app:v1.0.0"

  # SOPS encrypted secrets - automatically decrypted and mounted as env
  sops_files = [
    { source_file = "${path.module}/secrets.enc.env" },
    { source_file = "${path.module}/api-keys.enc.json" }
  ]
}
```

**Note**: Requires [SOPS](https://github.com/getsops/sops) and appropriate key configuration (e.g., `SOPS_AGE_KEY_FILE` environment variable).

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
| `sops_secrets` | Map of SOPS secrets created (key => secret name) |

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
