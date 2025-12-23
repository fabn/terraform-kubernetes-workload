# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for the deployment"
  type        = string
}

variable "name" {
  description = "Name for the deployment and associated resources"
  type        = string
}

variable "image" {
  description = "Docker image to deploy (e.g., nginx:latest)"
  type        = string
}

# =============================================================================
# Namespace Configuration
# =============================================================================

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = false
}

# =============================================================================
# Deployment Configuration
# =============================================================================

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
}

variable "command" {
  description = "Container command (entrypoint override)"
  type        = list(string)
  default     = []
}

variable "args" {
  description = "Container arguments"
  type        = list(string)
  default     = []
}

variable "working_dir" {
  description = "Container working directory"
  type        = string
  default     = null
  nullable    = true
}

variable "image_pull_secrets" {
  description = "Name of the image pull secret for private registries"
  type        = string
  default     = null
  nullable    = true
}

variable "service_account_name" {
  description = "Service account to use for the pods"
  type        = string
  default     = null
  nullable    = true
}

# =============================================================================
# Resource Requests and Limits
# =============================================================================

variable "cpu_requests" {
  description = "CPU resource request (e.g., 100m, 0.5)"
  type        = string
  default     = null
}

variable "memory_requests" {
  description = "Memory resource request (e.g., 128Mi, 1Gi)"
  type        = string
  default     = null
}

variable "memory_limits" {
  description = "Memory resource limit. Defaults to memory_requests if not set"
  type        = string
  default     = null
}

# =============================================================================
# Networking
# =============================================================================

variable "ports" {
  description = "Map of port names to port numbers (e.g., { http = 8080, metrics = 9090 })"
  type        = map(number)
  default     = {}
}

variable "service_type" {
  description = "Kubernetes Service type. Set to null to skip service creation"
  type        = string
  default     = "ClusterIP"
  nullable    = true

  validation {
    condition     = var.service_type == null ? true : contains(["ClusterIP", "LoadBalancer", "NodePort"], var.service_type)
    error_message = "service_type must be ClusterIP, LoadBalancer, NodePort, or null"
  }
}

# =============================================================================
# Ingress Configuration
# =============================================================================

variable "ingress_hostnames" {
  description = "List of hostnames for ingress rules. Empty list disables ingress"
  type        = list(string)
  default     = []
}

variable "ingress_annotations" {
  description = "Additional annotations for the ingress resource"
  type        = map(string)
  default     = {}
}

variable "ingress_tls_enabled" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = true
}

variable "ingress_tls_secret_name" {
  description = "TLS secret name. Auto-generated as {name}-tls-ingress if not set"
  type        = string
  default     = null
  nullable    = true
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., nginx)"
  type        = string
  default     = null
  nullable    = true
}

variable "ingress_acme_enabled" {
  description = "Add kubernetes.io/tls-acme annotation for automatic TLS certificates"
  type        = bool
  default     = true
}

# =============================================================================
# Canary Deployment (nginx-ingress)
# =============================================================================

variable "canary" {
  description = "Canary deployment configuration for nginx ingress controller"
  type = object({
    enabled = bool
    weight  = optional(number, 0)
  })
  default = {
    enabled = false
    weight  = 0
  }
}

# =============================================================================
# Environment Variables
# =============================================================================

variable "envs" {
  description = "Plain environment variables as key-value pairs"
  type        = map(string)
  default     = {}
}

variable "config_map_refs" {
  description = "List of ConfigMap names to mount as environment variables"
  type        = list(string)
  default     = []
}

variable "secret_refs" {
  description = "List of Secret names to mount as environment variables"
  type        = list(string)
  default     = []
}

variable "env_from" {
  description = "Advanced envFrom configuration with optional prefix"
  type = list(object({
    prefix     = optional(string)
    config_map = optional(string)
    secret     = optional(string)
  }))
  default = []
}

variable "env_value_from" {
  description = "Environment variables from individual secret or configmap keys"
  type = list(object({
    name = string
    secret_key_ref = optional(object({
      name     = string
      key      = string
      optional = optional(bool, false)
    }))
    config_map_key_ref = optional(object({
      name     = string
      key      = string
      optional = optional(bool, false)
    }))
  }))
  default = []
}

# =============================================================================
# Volumes
# =============================================================================

variable "volumes" {
  description = "Volume definitions with mount configurations"
  type = list(object({
    name                    = string
    mount_path              = string
    sub_path                = optional(string)
    read_only               = optional(bool, false)
    secret                  = optional(string)
    config_map              = optional(string)
    persistent_volume_claim = optional(string)
    mode                    = optional(string)
  }))
  default = []
}

variable "empty_dirs" {
  description = "List of paths to create as emptyDir volumes (in-memory)"
  type        = list(string)
  default     = []
}

# =============================================================================
# Health Probes
# =============================================================================

variable "http_probe_path" {
  description = "HTTP path for liveness and readiness probes"
  type        = string
  default     = null
  nullable    = true
}

variable "startup_probe_path" {
  description = "HTTP path for startup probe. Defaults to http_probe_path if not set"
  type        = string
  default     = null
  nullable    = true
}

variable "probe_port" {
  description = "Named port for health probes"
  type        = string
  default     = "http"
}

# =============================================================================
# Pod Scheduling
# =============================================================================

variable "anti_affinity" {
  description = "Pod anti-affinity strategy: 'soft' (preferred), 'hard' (required), or null (disabled)"
  type        = string
  default     = "soft"
  nullable    = true

  validation {
    condition     = var.anti_affinity == null ? true : contains(["soft", "hard"], var.anti_affinity)
    error_message = "anti_affinity must be 'soft', 'hard', or null"
  }
}

# =============================================================================
# Labels and Annotations
# =============================================================================

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "pod_annotations" {
  description = "Additional annotations for pod template"
  type        = map(string)
  default     = {}
}

variable "deployment_annotations" {
  description = "Additional annotations for the deployment resource"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Init Container
# =============================================================================

variable "init_container" {
  description = "Init container configuration (e.g., for database migrations)"
  type = object({
    command = optional(list(string))
    args    = optional(list(string))
    image   = optional(string)
  })
  default = null
}

# =============================================================================
# Optional Feature Flags
# =============================================================================

variable "hpa_enabled" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = false
}

variable "hpa_config" {
  description = "HPA configuration when hpa_enabled is true"
  type = object({
    min_replicas = optional(number, 1)
    max_replicas = number
    metrics = optional(object({
      cpu_utilization    = optional(number)
      memory_utilization = optional(number)
      pod_metrics        = optional(map(string), {})
    }), {})
  })
  default = null
}

variable "pdb_enabled" {
  description = "Enable Pod Disruption Budget"
  type        = bool
  default     = false
}

variable "pdb_config" {
  description = "PDB configuration when pdb_enabled is true"
  type = object({
    min_available   = optional(string)
    max_unavailable = optional(string, "1")
  })
  default = null
}

variable "service_monitor_enabled" {
  description = "Enable Prometheus ServiceMonitor"
  type        = bool
  default     = false
}

variable "service_monitor_config" {
  description = "ServiceMonitor configuration when service_monitor_enabled is true"
  type = object({
    port     = optional(string, "metrics")
    path     = optional(string, "/metrics")
    interval = optional(string, "30s")
  })
  default = null
}

# =============================================================================
# Datadog Integration (Optional)
# =============================================================================

variable "datadog_enabled" {
  description = "Enable Datadog integration (UST tags, log annotations, admission controller)"
  type        = bool
  default     = false
}

variable "datadog_ust_tags" {
  description = "Datadog Unified Service Tagging configuration"
  type = object({
    service = optional(string)
    env     = optional(string)
    version = optional(string)
    team    = optional(string)
  })
  default = {}
}

variable "datadog_log_config" {
  description = "Datadog log collection configuration"
  type = object({
    source  = optional(string)
    service = optional(string)
    exclude = optional(list(string), [])
  })
  default = {}
}

variable "datadog_checks" {
  description = "Datadog autodiscovery checks configuration"
  type        = map(any)
  default     = {}
}

variable "datadog_check_id" {
  description = "Datadog built-in check ID for autodiscovery (e.g., httpd, nginx)"
  type        = string
  default     = null
  nullable    = true
}

variable "datadog_admission_controller" {
  description = "Enable Datadog admission controller label for automatic env injection"
  type        = bool
  default     = true
}

# =============================================================================
# SOPS Integration (Optional)
# =============================================================================

variable "sops_files" {
  description = "List of SOPS encrypted files to decrypt and create as Kubernetes secrets. Each file creates a secret that is automatically added to the deployment's env_from."
  type = list(object({
    source_file = string
    input_type  = optional(string) # "json", "yaml", "dotenv", "raw" - auto-detected by provider if null
  }))
  default = []
}
