# =============================================================================
# E2E Deployment Tests - Runs against a real Kind cluster
# =============================================================================

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

variables {
  namespace        = "e2e-deployment"
  create_namespace = true
  image            = "ealen/echo-server:latest"
}

# -----------------------------------------------------------------------------
# Test: Minimal deployment
# -----------------------------------------------------------------------------
run "minimal_deploy" {
  variables {
    name = "minimal"
  }

  assert {
    condition     = output.deployment.metadata[0].name == "minimal"
    error_message = "Deployment name should match var.name"
  }

  assert {
    condition     = output.deployment.metadata[0].namespace == var.namespace
    error_message = "Deployment namespace should match var.namespace"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[0].image == var.image
    error_message = "Container image should match var.image"
  }

  assert {
    condition     = output.service == null
    error_message = "No service should be created without ports"
  }

  assert {
    condition     = output.ingress == null
    error_message = "No ingress should be created without hostnames"
  }

  assert {
    condition     = output.labels["app.kubernetes.io/name"] == "minimal"
    error_message = "Standard label app.kubernetes.io/name should be set"
  }
}

# -----------------------------------------------------------------------------
# Test: Anti-affinity soft (default)
# -----------------------------------------------------------------------------
run "anti_affinity_soft" {
  variables {
    name = "aa-soft"
  }

  assert {
    condition     = var.anti_affinity == "soft"
    error_message = "Default anti_affinity should be 'soft'"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].preferred_during_scheduling_ignored_during_execution[0].weight == 1
    error_message = "Soft anti-affinity should set weight to 1"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].preferred_during_scheduling_ignored_during_execution[0].pod_affinity_term[0].topology_key == "kubernetes.io/hostname"
    error_message = "Should use hostname topology key"
  }
}

# -----------------------------------------------------------------------------
# Test: Anti-affinity null (disabled)
# -----------------------------------------------------------------------------
run "anti_affinity_null" {
  variables {
    name          = "aa-null"
    anti_affinity = null
  }

  assert {
    condition     = length(output.deployment.spec[0].template[0].spec[0].affinity) == 0
    error_message = "No affinity should be configured when anti_affinity is null"
  }
}

# -----------------------------------------------------------------------------
# Test: Anti-affinity hard
# -----------------------------------------------------------------------------
run "anti_affinity_hard" {
  variables {
    name          = "aa-hard"
    anti_affinity = "hard"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].affinity[0].pod_anti_affinity[0].required_during_scheduling_ignored_during_execution[0].topology_key == "kubernetes.io/hostname"
    error_message = "Hard anti-affinity should use required_during_scheduling with hostname topology"
  }
}

# -----------------------------------------------------------------------------
# Test: PDB enabled
# -----------------------------------------------------------------------------
run "pdb_enabled" {
  variables {
    name        = "with-pdb"
    pdb_enabled = true
  }

  assert {
    condition     = output.pdb != null
    error_message = "PDB should be created when pdb_enabled is true"
  }

  assert {
    condition     = output.pdb.metadata[0].name == "with-pdb"
    error_message = "PDB name should match deployment name"
  }

  assert {
    condition     = output.pdb.spec[0].max_unavailable == "1"
    error_message = "PDB max_unavailable should be 1 by default"
  }
}

# -----------------------------------------------------------------------------
# Test: Sidecar containers
# -----------------------------------------------------------------------------
run "sidecar_containers" {
  variables {
    name = "with-sidecars"
    ports = {
      http = 8080
    }
    sidecar_containers = [
      {
        name    = "logging-sidecar"
        image   = "busybox:latest"
        command = ["/bin/sh"]
        args    = ["-c", "while true; do echo 'Logging...'; sleep 30; done"]
      },
      {
        name    = "metrics-sidecar"
        image   = "busybox:latest"
        command = ["/bin/sh"]
        args    = ["-c", "while true; do echo 'Metrics...'; sleep 30; done"]
        ports = {
          metrics = 9090
        }
      }
    ]
  }

  assert {
    condition     = length(output.deployment.spec[0].template[0].spec[0].container) == 3
    error_message = "Should have main container plus two sidecars"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[0].name == "with-sidecars"
    error_message = "First container should be the main container"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[1].name == "logging-sidecar"
    error_message = "Second container should be logging-sidecar"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[2].name == "metrics-sidecar"
    error_message = "Third container should be metrics-sidecar"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[1].image == "busybox:latest"
    error_message = "Logging sidecar should use busybox:latest image"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[2].image == "busybox:latest"
    error_message = "Metrics sidecar should use busybox:latest image"
  }

  assert {
    condition     = length(output.deployment.spec[0].template[0].spec[0].container[2].port) == 1
    error_message = "Metrics sidecar should have one port configured"
  }

  assert {
    condition     = output.deployment.spec[0].template[0].spec[0].container[2].port[0].container_port == 9090
    error_message = "Metrics sidecar port should be 9090"
  }

  assert {
    condition     = output.service != null
    error_message = "Service should be created when ports exist"
  }

  assert {
    condition     = length(output.service.spec[0].port) == 2
    error_message = "Service should have two ports (main + sidecar metrics)"
  }
}

