# =============================================================================
# Sidecar Containers Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No sidecar containers by default
run "no_sidecar_containers_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container) == 1
    error_message = "Only main container should be configured by default"
  }
}

# Test: Single sidecar container
run "single_sidecar_container" {
  command = plan

  variables {
    sidecar_containers = [{
      name    = "logging-sidecar"
      image   = "fluent/fluentd:latest"
      command = ["fluentd"]
      args    = ["-c", "/fluentd/etc/fluent.conf"]
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container) == 2
    error_message = "Should have main container plus sidecar"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].name == "logging-sidecar"
    error_message = "Sidecar container name should be logging-sidecar"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].image == "fluent/fluentd:latest"
    error_message = "Sidecar container image should be fluent/fluentd:latest"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].command == tolist(["fluentd"])
    error_message = "Sidecar container command should be set"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].args == tolist(["-c", "/fluentd/etc/fluent.conf"])
    error_message = "Sidecar container args should be set"
  }
}

# Test: Multiple sidecar containers
run "multiple_sidecar_containers" {
  command = plan

  variables {
    sidecar_containers = [
      {
        name  = "logging-sidecar"
        image = "fluent/fluentd:latest"
      },
      {
        name  = "metrics-exporter"
        image = "prom/nginx-exporter:latest"
      }
    ]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container) == 3
    error_message = "Should have main container plus two sidecars"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].name == "logging-sidecar"
    error_message = "First sidecar name should be logging-sidecar"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[2].name == "metrics-exporter"
    error_message = "Second sidecar name should be metrics-exporter"
  }
}

# Test: Sidecar inherits main image when not specified
run "sidecar_inherits_main_image" {
  command = plan

  variables {
    sidecar_containers = [{
      name    = "helper"
      command = ["/bin/sh"]
      args    = ["-c", "while true; do sleep 30; done"]
    }]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].image == "nginx:latest"
    error_message = "Sidecar should inherit main container image when not specified"
  }
}

# Test: Sidecar inherits environment variables
run "sidecar_inherits_envs" {
  command = plan

  variables {
    envs = {
      APP_ENV   = "production"
      LOG_LEVEL = "info"
    }
    sidecar_containers = [{
      name  = "sidecar"
      image = "busybox:latest"
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].env) == 2
    error_message = "Sidecar should inherit environment variables"
  }

  assert {
    condition     = contains([for e in kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].env : e.name], "APP_ENV")
    error_message = "Sidecar should have APP_ENV environment variable"
  }
}

# Test: Sidecar inherits volume mounts
run "sidecar_inherits_volumes" {
  command = plan

  variables {
    volumes = [{
      name       = "shared-data"
      mount_path = "/data"
      config_map = "app-config"
    }]
    sidecar_containers = [{
      name  = "sidecar"
      image = "busybox:latest"
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].volume_mount) == 1
    error_message = "Sidecar should inherit volume mounts"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].volume_mount[0].mount_path == "/data"
    error_message = "Sidecar volume mount path should be /data"
  }
}

# Test: Sidecar inherits emptyDir volumes
run "sidecar_inherits_empty_dirs" {
  command = plan

  variables {
    empty_dirs = ["/tmp"]
    sidecar_containers = [{
      name  = "sidecar"
      image = "busybox:latest"
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].volume_mount) == 1
    error_message = "Sidecar should inherit emptyDir volume mounts"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].volume_mount[0].mount_path == "/tmp"
    error_message = "Sidecar emptyDir mount path should be /tmp"
  }
}

# Test: Sidecar inherits working directory
run "sidecar_inherits_working_dir" {
  command = plan

  variables {
    working_dir = "/app"
    sidecar_containers = [{
      name  = "sidecar"
      image = "busybox:latest"
    }]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].working_dir == "/app"
    error_message = "Sidecar should inherit working directory"
  }
}
