# E2E Test Variables
# Subset of variables from parent module needed for E2E tests

variable "name" {
  description = "Name of the deployment"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "image" {
  description = "Container image"
  type        = string
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "ports" {
  description = "Container ports"
  type        = map(number)
  default     = {}
}

variable "ingress_hostnames" {
  description = "Ingress hostnames"
  type        = list(string)
  default     = []
}

variable "ingress_tls_enabled" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = true
}

variable "anti_affinity" {
  description = "Anti-affinity type (soft, hard, or null)"
  type        = string
  default     = "soft"
  nullable    = true
}

variable "pdb_enabled" {
  description = "Enable PDB"
  type        = bool
  default     = false
}

variable "sops_files" {
  description = "SOPS encrypted files"
  type = list(object({
    source_file = string
    input_type  = optional(string)
  }))
  default = []
}
