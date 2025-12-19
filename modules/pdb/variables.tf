# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for the PDB"
  type        = string
}

variable "name" {
  description = "Name for the PDB resource"
  type        = string
}

variable "selector" {
  description = "Label selector for matching pods"
  type        = map(string)
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "labels" {
  description = "Labels to apply to the PDB"
  type        = map(string)
  default     = {}
}

variable "min_available" {
  description = "Minimum number of pods that must be available (mutually exclusive with max_unavailable)"
  type        = string
  default     = null
  nullable    = true
}

variable "max_unavailable" {
  description = "Maximum number of pods that can be unavailable (mutually exclusive with min_available)"
  type        = string
  default     = null
  nullable    = true
}
