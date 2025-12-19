output "hpa" {
  description = "The kubernetes_horizontal_pod_autoscaler_v2 resource"
  value       = kubernetes_horizontal_pod_autoscaler_v2.this
}

output "name" {
  description = "The name of the HPA"
  value       = kubernetes_horizontal_pod_autoscaler_v2.this.metadata[0].name
}
