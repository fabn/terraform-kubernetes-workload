# E2E Test Module
# This module references the parent workload module for testing

module "workload" {
  source = "../"

  name             = var.name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  image            = var.image
  replicas         = var.replicas
  ports            = var.ports

  # Ingress
  ingress_hostnames   = var.ingress_hostnames
  ingress_tls_enabled = var.ingress_tls_enabled

  # Anti-affinity
  anti_affinity = var.anti_affinity

  # PDB
  pdb_enabled = var.pdb_enabled
}
