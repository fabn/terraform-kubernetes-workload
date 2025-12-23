# =============================================================================
# Volumes Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No volumes by default
run "no_volumes_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume) == 0
    error_message = "No volumes should be configured by default"
  }
}

# Test: ConfigMap volume
run "configmap_volume" {
  command = plan

  variables {
    volumes = [{
      name       = "config"
      mount_path = "/app/config"
      config_map = "app-config"
      read_only  = true
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume) == 1
    error_message = "One volume should be configured"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume[0].config_map[0].name == "app-config"
    error_message = "ConfigMap name should be app-config"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].volume_mount[0].mount_path == "/app/config"
    error_message = "Volume mount path should be /app/config"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].volume_mount[0].read_only == true
    error_message = "Volume mount should be read-only"
  }
}

# Test: Secret volume
run "secret_volume" {
  command = plan

  variables {
    volumes = [{
      name       = "secrets"
      mount_path = "/app/secrets"
      secret     = "app-secrets"
      mode       = "0400"
    }]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume[0].secret[0].secret_name == "app-secrets"
    error_message = "Secret name should be app-secrets"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume[0].secret[0].default_mode == "0400"
    error_message = "Secret default mode should be 0400"
  }
}

# Test: EmptyDir volumes
run "emptydir_volumes" {
  command = plan

  variables {
    empty_dirs = ["/tmp", "/app/cache"]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume) == 2
    error_message = "Two emptyDir volumes should be configured"
  }
}

# Test: SubPath mount
run "subpath_mount" {
  command = plan

  variables {
    volumes = [{
      name       = "config"
      mount_path = "/app/config/settings.yaml"
      config_map = "app-config"
      sub_path   = "settings.yaml"
    }]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].volume_mount[0].sub_path == "settings.yaml"
    error_message = "SubPath should be settings.yaml"
  }
}

# Test: PersistentVolumeClaim volume
run "pvc_volume" {
  command = plan

  variables {
    volumes = [{
      name                    = "data"
      mount_path              = "/data"
      persistent_volume_claim = "app-data-pvc"
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume) == 1
    error_message = "One volume should be configured"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume[0].persistent_volume_claim[0].claim_name == "app-data-pvc"
    error_message = "PVC claim name should be app-data-pvc"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].volume_mount[0].mount_path == "/data"
    error_message = "Volume mount path should be /data"
  }
}

# Test: PersistentVolumeClaim volume with read_only
run "pvc_volume_readonly" {
  command = plan

  variables {
    volumes = [{
      name                    = "data"
      mount_path              = "/data"
      persistent_volume_claim = "app-data-pvc"
      read_only               = true
    }]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].volume[0].persistent_volume_claim[0].read_only == true
    error_message = "PVC should be mounted read-only"
  }
}
