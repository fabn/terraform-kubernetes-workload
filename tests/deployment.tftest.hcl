# =============================================================================
# Deployment Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: Basic deployment creation
run "basic_deployment" {
  command = plan

  assert {
    condition     = kubernetes_deployment_v1.this.metadata[0].name == "test-app"
    error_message = "Deployment name should match var.name"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.metadata[0].namespace == "test-ns"
    error_message = "Deployment namespace should match var.namespace"
  }

  assert {
    condition     = tonumber(kubernetes_deployment_v1.this.spec[0].replicas) == 1
    error_message = "Default replicas should be 1"
  }
}

# Test: Custom replicas
run "custom_replicas" {
  command = plan

  variables {
    replicas = 3
  }

  assert {
    condition     = tonumber(kubernetes_deployment_v1.this.spec[0].replicas) == 3
    error_message = "Replicas should be 3"
  }
}

# Test: Container image
run "container_image" {
  command = plan

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image == "nginx:latest"
    error_message = "Container image should match var.image"
  }
}

# Test: Custom command and args
run "custom_command_args" {
  command = plan

  variables {
    command = ["./entrypoint.sh"]
    args    = ["--port", "8080"]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].command == tolist(["./entrypoint.sh"])
    error_message = "Command should be set"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].args == tolist(["--port", "8080"])
    error_message = "Args should be set"
  }
}

# Test: Labels
run "standard_labels" {
  command = plan

  assert {
    condition     = kubernetes_deployment_v1.this.metadata[0].labels["app.kubernetes.io/name"] == "test-app"
    error_message = "Standard label app.kubernetes.io/name should be set"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.metadata[0].labels["app.kubernetes.io/managed-by"] == "terraform"
    error_message = "Standard label app.kubernetes.io/managed-by should be set"
  }
}

# Test: Custom labels
run "custom_labels" {
  command = plan

  variables {
    labels = {
      team        = "platform"
      environment = "staging"
    }
  }

  assert {
    condition     = kubernetes_deployment_v1.this.metadata[0].labels["team"] == "platform"
    error_message = "Custom label team should be set"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.metadata[0].labels["environment"] == "staging"
    error_message = "Custom label environment should be set"
  }
}
