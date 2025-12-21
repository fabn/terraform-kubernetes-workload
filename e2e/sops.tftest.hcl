# =============================================================================
# E2E SOPS Secrets Tests - Runs against a real Kind cluster
# =============================================================================
# Prerequisites:
# - SOPS installed
# - SOPS_AGE_KEY_FILE environment variable set to sops/test.agekey

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

provider "sops" {}

variables {
  namespace        = "e2e-sops"
  create_namespace = true
  image            = "ealen/echo-server:latest"
}

# -----------------------------------------------------------------------------
# Test: SOPS secrets from .env file
# -----------------------------------------------------------------------------
run "sops_env_file" {
  variables {
    name = "sops-env"
    sops_files = [
      { source_file = "./sops/secrets.enc.env" }
    ]
  }

  assert {
    condition     = length(output.sops_secrets) == 1
    error_message = "Should create exactly 1 SOPS secret"
  }

  assert {
    condition     = can(output.sops_secrets["secrets"])
    error_message = "Secret key should be 'secrets' (basename without extension)"
  }

  assert {
    condition     = startswith(output.sops_secrets["secrets"], "sops-env-secrets-")
    error_message = "Secret name should start with 'sops-env-secrets-'"
  }

  # Verify the deployment has env_from with the SOPS secret
  assert {
    condition = length([
      for ef in output.deployment.spec[0].template[0].spec[0].container[0].env_from :
      ef if ef.secret_ref != null && can(ef.secret_ref[0].name) && startswith(ef.secret_ref[0].name, "sops-env-secrets-")
    ]) == 1
    error_message = "Deployment should have env_from with SOPS secret"
  }
}

# -----------------------------------------------------------------------------
# Test: SOPS secrets from JSON file
# -----------------------------------------------------------------------------
run "sops_json_file" {
  variables {
    name = "sops-json"
    sops_files = [
      { source_file = "./sops/api-keys.enc.json" }
    ]
  }

  assert {
    condition     = length(output.sops_secrets) == 1
    error_message = "Should create exactly 1 SOPS secret"
  }

  assert {
    condition     = can(output.sops_secrets["api-keys"])
    error_message = "Secret key should be 'api-keys' (basename without extension)"
  }

  assert {
    condition     = startswith(output.sops_secrets["api-keys"], "sops-json-api-keys-")
    error_message = "Secret name should start with 'sops-json-api-keys-'"
  }
}

# -----------------------------------------------------------------------------
# Test: Multiple SOPS files
# -----------------------------------------------------------------------------
run "sops_multiple_files" {
  variables {
    name = "sops-multi"
    sops_files = [
      { source_file = "./sops/secrets.enc.env" },
      { source_file = "./sops/api-keys.enc.json" }
    ]
  }

  assert {
    condition     = length(output.sops_secrets) == 2
    error_message = "Should create 2 SOPS secrets"
  }

  assert {
    condition     = can(output.sops_secrets["secrets"]) && can(output.sops_secrets["api-keys"])
    error_message = "Should have 'secrets' and 'api-keys' keys"
  }

  # Verify deployment has both secrets in env_from
  assert {
    condition = length([
      for ef in output.deployment.spec[0].template[0].spec[0].container[0].env_from :
      ef if ef.secret_ref != null
    ]) >= 2
    error_message = "Deployment should have at least 2 secret refs from SOPS"
  }
}

# -----------------------------------------------------------------------------
# Test: No SOPS files (default behavior)
# -----------------------------------------------------------------------------
run "sops_disabled" {
  variables {
    name       = "sops-disabled"
    sops_files = []
  }

  assert {
    condition     = length(output.sops_secrets) == 0
    error_message = "Should not create any SOPS secrets when sops_files is empty"
  }
}
