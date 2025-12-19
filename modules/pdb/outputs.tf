output "pdb" {
  description = "The kubernetes_pod_disruption_budget_v1 resource"
  value       = kubernetes_pod_disruption_budget_v1.this
}

output "name" {
  description = "The name of the PDB"
  value       = kubernetes_pod_disruption_budget_v1.this.metadata[0].name
}
