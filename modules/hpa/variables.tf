# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for the HPA"
  type        = string
}

variable "name" {
  description = "Name for the HPA resource"
  type        = string
}

variable "target_ref" {
  description = "Reference to the scalable resource"
  type = object({
    api_version = string
    kind        = string
    name        = string
  })
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "labels" {
  description = "Labels to apply to the HPA"
  type        = map(string)
  default     = {}
}

variable "metrics" {
  description = "HPA metrics configuration"
  type = object({
    cpu_utilization    = optional(number)
    memory_utilization = optional(number)
    pod_metrics        = optional(map(string), {})
  })
  default = {}
}
