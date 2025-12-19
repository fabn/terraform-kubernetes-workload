# =============================================================================
# Environment Variables Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: Plain environment variables
run "plain_env_vars" {
  command = plan

  variables {
    envs = {
      LOG_LEVEL = "debug"
      APP_ENV   = "test"
    }
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].env) == 2
    error_message = "Two env vars should be configured"
  }
}

# Test: ConfigMap reference
run "configmap_ref" {
  command = plan

  variables {
    config_map_refs = ["app-config", "common-config"]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].env_from) >= 2
    error_message = "Two configmap refs should be configured"
  }
}

# Test: Secret reference
run "secret_ref" {
  command = plan

  variables {
    secret_refs = ["app-secrets"]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].env_from) >= 1
    error_message = "Secret ref should be configured"
  }
}

# Test: Env from with prefix
run "env_from_with_prefix" {
  command = plan

  variables {
    env_from = [{
      prefix     = "DB_"
      config_map = "database-config"
    }]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].env_from[0].prefix == "DB_"
    error_message = "Env from prefix should be DB_"
  }
}

# Test: Env value from secret key
run "env_value_from_secret" {
  command = plan

  variables {
    env_value_from = [{
      name = "DATABASE_URL"
      secret_key_ref = {
        name = "database-credentials"
        key  = "url"
      }
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].env) >= 1
    error_message = "Env value from should be configured"
  }
}

# Test: Env value from configmap key
run "env_value_from_configmap" {
  command = plan

  variables {
    env_value_from = [{
      name = "API_URL"
      config_map_key_ref = {
        name = "api-config"
        key  = "url"
      }
    }]
  }

  assert {
    condition     = length(kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].env) >= 1
    error_message = "Env value from configmap should be configured"
  }
}
