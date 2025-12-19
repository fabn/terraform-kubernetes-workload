# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for the ServiceMonitor"
  type        = string
}

variable "name" {
  description = "Name for the ServiceMonitor resource"
  type        = string
}

variable "selector" {
  description = "Label selector for matching services"
  type        = map(string)
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "labels" {
  description = "Labels to apply to the ServiceMonitor"
  type        = map(string)
  default     = {}
}

variable "endpoints" {
  description = "List of endpoint configurations"
  type = list(object({
    port     = string
    path     = optional(string, "/metrics")
    interval = optional(string, "30s")
  }))
  default = [{
    port     = "metrics"
    path     = "/metrics"
    interval = "30s"
  }]
}
