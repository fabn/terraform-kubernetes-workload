# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for the Secret"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the Secret name. Final name will be {prefix}-{sha8}"
  type        = string
}

# =============================================================================
# Optional Variables
# =============================================================================

variable "type" {
  description = "The type of Secret (e.g., Opaque, kubernetes.io/tls, kubernetes.io/dockerconfigjson)"
  type        = string
  default     = null
  nullable    = true
}

variable "data" {
  description = "Secret data as key-value pairs (values will be base64 encoded automatically)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "binary_data" {
  description = "Binary secret data (already base64 encoded)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "labels" {
  description = "Labels to apply to the Secret"
  type        = map(string)
  default     = {}
}
