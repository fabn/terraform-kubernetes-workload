# =============================================================================
# Pod Affinity + Node Selector Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: no pod affinity / node selector by default
run "none_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_affinity) == 0
    error_message = "No pod affinity should be configured by default"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].node_selector == null
    error_message = "No node selector should be configured by default"
  }
}

# Test: node selector
run "node_selector" {
  command = plan

  variables {
    node_selector = { "disktype" = "ssd" }
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].node_selector["disktype"] == "ssd"
    error_message = "Node selector should be forwarded"
  }
}

# Test: required + preferred pod affinity, standalone (anti_affinity disabled)
run "pod_affinity_required_and_preferred" {
  command = plan

  variables {
    anti_affinity = null
    pod_affinity = {
      required = [
        {
          topology_key = "kubernetes.io/hostname"
          match_labels = { "app" = "cache" }
        },
      ]
      preferred = [
        {
          weight       = 50
          topology_key = "topology.kubernetes.io/zone"
          match_expressions = [
            { key = "tier", operator = "In", values = ["backend"] },
          ]
        },
      ]
    }
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_affinity) == 1
    error_message = "Pod affinity should be configured"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_affinity[0].required_during_scheduling_ignored_during_execution[0].topology_key == "kubernetes.io/hostname"
    error_message = "Required pod affinity topology key should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_affinity[0].required_during_scheduling_ignored_during_execution[0].label_selector[0].match_labels["app"] == "cache"
    error_message = "Required pod affinity label selector should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_affinity[0].preferred_during_scheduling_ignored_during_execution[0].weight == 50
    error_message = "Preferred pod affinity weight should be forwarded"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity) == 0
    error_message = "Pod anti-affinity should be absent when anti_affinity is null"
  }
}
