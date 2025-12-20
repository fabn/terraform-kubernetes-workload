# E2E Test Outputs
# Expose parent module outputs for test assertions

output "name" {
  value = module.workload.name
}

output "namespace" {
  value = module.workload.namespace
}

output "deployment" {
  value = module.workload.deployment
}

output "service" {
  value = module.workload.service
}

output "ingress" {
  value = module.workload.ingress
}

output "labels" {
  value = module.workload.labels
}

output "pdb" {
  value = module.workload.pdb
}
