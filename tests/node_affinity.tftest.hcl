# =============================================================================
# Node Affinity Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: no node affinity by default (only the default soft pod anti-affinity)
run "no_node_affinity_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].node_affinity) == 0
    error_message = "No node affinity should be configured by default"
  }
}

# Test: required + preferred node affinity, standalone (anti_affinity disabled)
run "node_affinity_required_and_preferred" {
  command = plan

  variables {
    anti_affinity = null
    node_affinity = {
      required = [
        { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
        { key = "eks.amazonaws.com/instance-category", operator = "NotIn", values = ["t"] },
      ]
      preferred = [
        { weight = 100, key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
      ]
    }
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].node_affinity) == 1
    error_message = "Node affinity should be configured"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity) == 0
    error_message = "Pod anti-affinity should be absent when anti_affinity is null"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].node_affinity[0].required_during_scheduling_ignored_during_execution[0].node_selector_term[0].match_expressions) == 2
    error_message = "Both required match expressions should be ANDed into one node-selector term"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].node_affinity[0].preferred_during_scheduling_ignored_during_execution) == 1
    error_message = "One preferred scheduling term should be configured"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].node_affinity[0].preferred_during_scheduling_ignored_during_execution[0].weight == 100
    error_message = "Preferred term weight should be preserved"
  }
}

# Test: node affinity coexists with the default soft pod anti-affinity
run "node_affinity_with_anti_affinity" {
  command = plan

  variables {
    node_affinity = {
      required = [
        { key = "eks.amazonaws.com/instance-category", operator = "NotIn", values = ["t"] },
      ]
    }
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].node_affinity) == 1
    error_message = "Node affinity should be configured alongside anti-affinity"
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity) == 1
    error_message = "Default soft pod anti-affinity should still be present"
  }
}
