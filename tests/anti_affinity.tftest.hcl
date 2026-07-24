# =============================================================================
# Anti-Affinity Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: Soft anti-affinity by default
run "soft_anti_affinity_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity) == 1
    error_message = "Affinity should be configured by default"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].preferred_during_scheduling_ignored_during_execution) == 1
    error_message = "Soft anti-affinity should be configured by default"
  }
}

# Test: Hard anti-affinity
run "hard_anti_affinity" {
  command = plan

  variables {
    anti_affinity = "hard"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].required_during_scheduling_ignored_during_execution) == 1
    error_message = "Hard anti-affinity should be configured"
  }
}

# Test: No anti-affinity
run "no_anti_affinity" {
  command = plan

  variables {
    anti_affinity = null
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity) == 0
    error_message = "No affinity should be configured when anti_affinity is null"
  }
}

# Test: Raw pod_anti_affinity escape hatch, standalone (shorthand disabled)
run "raw_pod_anti_affinity" {
  command = plan

  variables {
    anti_affinity = null
    pod_anti_affinity = {
      required = [
        {
          topology_key = "kubernetes.io/hostname"
          match_labels = { "app" = "web" }
        },
      ]
      preferred = [
        {
          weight       = 50
          topology_key = "topology.kubernetes.io/zone"
          match_expressions = [
            { key = "tier", operator = "In", values = ["frontend"] },
          ]
        },
      ]
    }
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity) == 1
    error_message = "Pod anti-affinity should be configured from raw input"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].required_during_scheduling_ignored_during_execution[0].topology_key == "kubernetes.io/hostname"
    error_message = "Raw required anti-affinity topology key should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].required_during_scheduling_ignored_during_execution[0].label_selector[0].match_labels["app"] == "web"
    error_message = "Raw required anti-affinity label selector should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].preferred_during_scheduling_ignored_during_execution[0].weight == 50
    error_message = "Raw preferred anti-affinity weight should be forwarded"
  }
}

# Test: Raw pod_anti_affinity is additive to the shorthand
run "raw_pod_anti_affinity_additive_to_shorthand" {
  command = plan

  variables {
    anti_affinity = "soft"
    pod_anti_affinity = {
      required = [
        {
          topology_key = "topology.kubernetes.io/zone"
          match_labels = { "app" = "web" }
        },
      ]
    }
  }

  # Shorthand soft term + no raw preferred terms
  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].preferred_during_scheduling_ignored_during_execution) == 1
    error_message = "Soft shorthand term should still render alongside raw terms"
  }

  # Raw required term rendered
  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].required_during_scheduling_ignored_during_execution) == 1
    error_message = "Raw required anti-affinity term should render alongside the shorthand"
  }
}
