# =============================================================================
# Topology Spread Constraints Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: none by default
run "none_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint) == 0
    error_message = "No topology spread constraints should be configured by default"
  }
}

# Test: constraint with default (selector-derived) label selector
run "default_label_selector" {
  command = plan

  variables {
    topology_spread_constraints = [
      {
        max_skew           = 1
        topology_key       = "topology.kubernetes.io/zone"
        when_unsatisfiable = "DoNotSchedule"
      },
    ]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint) == 1
    error_message = "One topology spread constraint should be configured"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].max_skew == 1
    error_message = "max_skew should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].topology_key == "topology.kubernetes.io/zone"
    error_message = "topology_key should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].when_unsatisfiable == "DoNotSchedule"
    error_message = "when_unsatisfiable should be forwarded"
  }

  # Defaults to the workload's own selector labels
  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].label_selector[0].match_labels["app.kubernetes.io/name"] == "test-app"
    error_message = "label_selector should default to the workload's own pod labels"
  }
}

# Test: explicit label selector + min_domains
run "explicit_label_selector" {
  command = plan

  variables {
    topology_spread_constraints = [
      {
        max_skew           = 2
        topology_key       = "kubernetes.io/hostname"
        when_unsatisfiable = "ScheduleAnyway"
        min_domains        = 3
        label_selector = {
          match_labels = { "app" = "custom" }
          match_expressions = [
            { key = "tier", operator = "In", values = ["backend"] },
          ]
        }
      },
    ]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].min_domains == 3
    error_message = "min_domains should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].label_selector[0].match_labels["app"] == "custom"
    error_message = "explicit label_selector match_labels should be forwarded"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].topology_spread_constraint[0].label_selector[0].match_expressions[0].key == "tier"
    error_message = "explicit label_selector match_expressions should be forwarded"
  }
}

# Test: invalid when_unsatisfiable is rejected
run "invalid_when_unsatisfiable" {
  command = plan

  variables {
    topology_spread_constraints = [
      {
        max_skew           = 1
        topology_key       = "topology.kubernetes.io/zone"
        when_unsatisfiable = "Nope"
      },
    ]
  }

  expect_failures = [
    var.topology_spread_constraints,
  ]
}
