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
  description = "Datadog log collection configuration. Set enabled = false to exclude the container from log collection entirely via the ad.datadoghq.com/<container>.logs_exclude annotation (requires Datadog Agent v7.45+); source, service and exclude cannot be combined with enabled = false."
  type = object({
    enabled = optional(bool, true)
    source  = optional(string)
    service = optional(string)
    exclude = optional(list(string), [])
  })
  default = {}
  validation {
    condition = (
      var.log_config.enabled ||
      (var.log_config.source == null && var.log_config.service == null && length(coalesce(var.log_config.exclude, [])) == 0)
    )
    error_message = "log_config.enabled = false excludes the container from log collection, so source, service and exclude must not be set."
  }
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
