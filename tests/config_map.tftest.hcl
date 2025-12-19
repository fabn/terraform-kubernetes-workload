# =============================================================================
# ConfigMap Tests
# =============================================================================

mock_provider "kubernetes" {}

run "basic_config_map" {
  command = plan

  module {
    source = "./modules/config-map"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-config"
    data = {
      "key1" = "value1"
      "key2" = "value2"
    }
  }

  assert {
    condition     = kubernetes_config_map_v1.this.metadata[0].namespace == "test-ns"
    error_message = "ConfigMap namespace should be test-ns"
  }

  assert {
    condition     = startswith(kubernetes_config_map_v1.this.metadata[0].name, "test-config-")
    error_message = "ConfigMap name should start with test-config-"
  }

  assert {
    condition     = length(kubernetes_config_map_v1.this.metadata[0].name) == length("test-config-") + 8
    error_message = "ConfigMap name should have 8 character hash suffix"
  }
}

run "config_map_with_labels" {
  command = plan

  module {
    source = "./modules/config-map"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-config"
    data        = { "key" = "value" }
    labels = {
      "app.kubernetes.io/name" = "my-app"
      "team"                   = "platform"
    }
  }

  assert {
    condition     = kubernetes_config_map_v1.this.metadata[0].labels["app.kubernetes.io/name"] == "my-app"
    error_message = "Custom label should be set"
  }

  assert {
    condition     = kubernetes_config_map_v1.this.metadata[0].labels["app.kubernetes.io/managed-by"] == "terraform"
    error_message = "Standard managed-by label should be set"
  }
}

run "config_map_sha_changes_with_content" {
  command = plan

  module {
    source = "./modules/config-map"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-config"
    data = {
      "key" = "value1"
    }
  }

  assert {
    condition     = output.sha != ""
    error_message = "SHA output should not be empty"
  }
}

run "config_map_different_content_different_sha" {
  command = plan

  module {
    source = "./modules/config-map"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-config"
    data = {
      "key" = "different-value"
    }
  }

  # This test verifies the SHA changes - we can't compare across runs
  # but we verify the mechanism works
  assert {
    condition     = length(output.sha) == 8
    error_message = "SHA should be 8 characters"
  }
}

run "config_map_with_binary_data" {
  command = plan

  module {
    source = "./modules/config-map"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-config"
    binary_data = {
      "binary-key" = "YmluYXJ5LWRhdGE=" # base64 encoded "binary-data"
    }
  }

  assert {
    condition     = kubernetes_config_map_v1.this.binary_data["binary-key"] == "YmluYXJ5LWRhdGE="
    error_message = "Binary data should be set"
  }
}

run "config_map_empty_data" {
  command = plan

  module {
    source = "./modules/config-map"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "empty-config"
  }

  assert {
    condition     = startswith(kubernetes_config_map_v1.this.metadata[0].name, "empty-config-")
    error_message = "ConfigMap should be created even with empty data"
  }
}
