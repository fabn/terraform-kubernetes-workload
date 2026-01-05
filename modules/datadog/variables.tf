# =============================================================================
# Required Variables
# =============================================================================

variable "container_name" {
  description = "Container name for Datadog check annotations"
  type        = string
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "admission_controller_enabled" {
  description = "Add admission.datadoghq.com/enabled LABEL for automatic env injection"
  type        = bool
  default     = true
}

variable "ust_tags" {
  description = "Datadog Unified Service Tagging configuration"
  type = object({
    service = optional(string)
    env     = optional(string)
    version = optional(string)
    team    = optional(string)
  })
  default = {}
}

variable "log_config" {
  description = "Datadog log collection configuration"
  type = object({
    source  = optional(string)
    service = optional(string)
    exclude = optional(list(string), [])
  })
  default = {}
}

variable "checks" {
  description = "Datadog autodiscovery checks (AD v2 format). Map of check_name => { instances = [...], init_config = {} }"
  type = map(object({
    instances   = list(any)
    init_config = optional(map(any), {})
  }))
  default = {}
}

variable "check_id" {
  description = "Datadog built-in check ID for autodiscovery (e.g., httpd, nginx, postgres)"
  type        = string
  default     = null
  nullable    = true
}
