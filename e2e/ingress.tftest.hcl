# =============================================================================
# E2E Ingress Tests - Runs against a real Kind cluster with ingress controller
# =============================================================================

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "kind-kind"
  }
}

# -----------------------------------------------------------------------------
# Step 1: Setup ingress controller
# -----------------------------------------------------------------------------
run "ingress_controller" {
  module {
    source = "./modules/ingress-controller"
  }
}

# -----------------------------------------------------------------------------
# Step 2: Deploy application with ingress
# -----------------------------------------------------------------------------
run "deploy_with_ingress" {
  variables {
    name                = "echo-server"
    namespace           = run.ingress_controller.namespace
    create_namespace    = false
    image               = "ealen/echo-server:latest"
    ports               = { http = 80 }
    ingress_hostnames   = ["echo.lvh.me"]
    ingress_tls_enabled = false
  }

  assert {
    condition     = output.deployment.metadata[0].name == "echo-server"
    error_message = "Deployment should be created with correct name"
  }

  assert {
    condition     = output.service != null
    error_message = "Service should be created when ports are defined"
  }

  assert {
    condition     = output.ingress != null
    error_message = "Ingress should be created when hostnames are defined"
  }

  assert {
    condition     = output.ingress.spec[0].rule[0].host == "echo.lvh.me"
    error_message = "Ingress hostname should match"
  }
}

# -----------------------------------------------------------------------------
# Step 3: Verify HTTP connectivity
# -----------------------------------------------------------------------------
run "verify_http" {
  module {
    source = "./modules/http"
  }

  variables {
    url            = "http://echo.lvh.me"
    max_retry      = 10
    retry_interval = 3
  }

  assert {
    condition     = output.status_code == 200
    error_message = "Expected HTTP 200 OK from echo server"
  }

  assert {
    condition     = output.parsed.host.hostname == "echo.lvh.me"
    error_message = "Echo server should return the correct hostname"
  }
}
