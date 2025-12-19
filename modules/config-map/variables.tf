# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for the ConfigMap"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the ConfigMap name. Final name will be {prefix}-{sha8}"
  type        = string
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "data" {
  description = "Data to store in the ConfigMap as key-value pairs"
  type        = map(string)
  default     = {}
}

variable "binary_data" {
  description = "Binary data to store in the ConfigMap (base64 encoded)"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to the ConfigMap"
  type        = map(string)
  default     = {}
}
