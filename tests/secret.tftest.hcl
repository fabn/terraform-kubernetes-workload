# =============================================================================
# Secret Tests
# =============================================================================

mock_provider "kubernetes" {}

run "basic_secret" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-secret"
    data = {
      "password" = "secret-value"
    }
  }

  assert {
    condition     = kubernetes_secret_v1.this.metadata[0].namespace == "test-ns"
    error_message = "Secret namespace should be test-ns"
  }

  assert {
    condition     = startswith(kubernetes_secret_v1.this.metadata[0].name, "test-secret-")
    error_message = "Secret name should start with test-secret-"
  }

  assert {
    condition     = length(kubernetes_secret_v1.this.metadata[0].name) == length("test-secret-") + 8
    error_message = "Secret name should have 8 character hash suffix"
  }
}

run "secret_with_type" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-tls"
    type        = "kubernetes.io/tls"
    data = {
      "tls.crt" = "cert-content"
      "tls.key" = "key-content"
    }
  }

  assert {
    condition     = kubernetes_secret_v1.this.type == "kubernetes.io/tls"
    error_message = "Secret type should be kubernetes.io/tls"
  }
}

run "secret_with_labels" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-secret"
    data        = { "key" = "value" }
    labels = {
      "app.kubernetes.io/name" = "my-app"
      "team"                   = "platform"
    }
  }

  assert {
    condition     = kubernetes_secret_v1.this.metadata[0].labels["app.kubernetes.io/name"] == "my-app"
    error_message = "Custom label should be set"
  }

  assert {
    condition     = kubernetes_secret_v1.this.metadata[0].labels["app.kubernetes.io/managed-by"] == "terraform"
    error_message = "Standard managed-by label should be set"
  }
}

run "secret_sha_output" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-secret"
    data = {
      "key" = "value"
    }
  }

  assert {
    condition     = length(output.sha) == 8
    error_message = "SHA should be 8 characters"
  }

  assert {
    condition     = output.name != ""
    error_message = "Name output should not be empty"
  }
}

run "secret_with_binary_data" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-secret"
    binary_data = {
      "binary-key" = "c2VjcmV0LWJpbmFyeQ==" # base64 encoded "secret-binary"
    }
  }

  assert {
    condition     = kubernetes_secret_v1.this.binary_data["binary-key"] == "c2VjcmV0LWJpbmFyeQ=="
    error_message = "Binary data should be set"
  }
}

run "secret_opaque_type_default" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "test-secret"
    data = {
      "key" = "value"
    }
  }

  # When type is null, Kubernetes defaults to Opaque
  assert {
    condition     = kubernetes_secret_v1.this.type == null
    error_message = "Secret type should be null (defaults to Opaque)"
  }
}

run "secret_docker_config_type" {
  command = plan

  module {
    source = "./modules/secret"
  }

  variables {
    namespace   = "test-ns"
    name_prefix = "registry-creds"
    type        = "kubernetes.io/dockerconfigjson"
    data = {
      ".dockerconfigjson" = "{\"auths\":{}}"
    }
  }

  assert {
    condition     = kubernetes_secret_v1.this.type == "kubernetes.io/dockerconfigjson"
    error_message = "Secret type should be kubernetes.io/dockerconfigjson"
  }
}
