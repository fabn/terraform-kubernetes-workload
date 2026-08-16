# =============================================================================
# Image Pull Policy Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: the :latest tag is mutable, so the image must be re-pulled every time
run "latest_tag_is_always" {
  command = plan

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "Always"
    error_message = "A :latest image should be pulled Always"
  }
}

# Test: an untagged reference is ":latest" implicitly
run "untagged_image_is_always" {
  command = plan

  variables {
    image = "nginx"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "Always"
    error_message = "An untagged image should be pulled Always"
  }
}

# Test: a pinned tag is immutable, the node cache can be trusted
run "pinned_tag_is_if_not_present" {
  command = plan

  variables {
    image = "my-registry/api:v1.0.0"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "IfNotPresent"
    error_message = "A pinned tag should be pulled IfNotPresent"
  }
}

# Test: a digest is the strongest pin there is
run "digest_is_if_not_present" {
  command = plan

  variables {
    image = "my-registry/api@sha256:0000000000000000000000000000000000000000000000000000000000000000"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "IfNotPresent"
    error_message = "A digest-pinned image should be pulled IfNotPresent"
  }
}

# Test: the port of a registry host is not a tag
run "registry_port_is_not_a_tag" {
  command = plan

  variables {
    image = "registry.internal:5000/team/api"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "Always"
    error_message = "A registry port should not be read as a tag: the image is untagged, so Always"
  }
}

# Test: a name containing "latest" is not the :latest tag
run "latest_in_name_is_not_latest_tag" {
  command = plan

  variables {
    image = "my-registry/latest-news:v2"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "IfNotPresent"
    error_message = "Only the :latest tag should force Always, not the substring"
  }
}

# Test: the policy is derived per image, so a pinned main container and a
# :latest sidecar each get their own
run "policy_is_per_container_image" {
  command = plan

  variables {
    image = "my-registry/api:v1.0.0"
    sidecar_containers = [
      {
        name  = "exporter"
        image = "nginx/nginx-prometheus-exporter:latest"
      },
      {
        name = "inherits-main-image"
      },
    ]
    init_container = {
      image   = "my-registry/migrations"
      command = ["./migrate"]
    }
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "IfNotPresent"
    error_message = "Main container is pinned, it should be IfNotPresent"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].image_pull_policy == "Always"
    error_message = "The :latest sidecar should be Always"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[2].image_pull_policy == "IfNotPresent"
    error_message = "A sidecar inheriting the pinned main image should be IfNotPresent"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].init_container[0].image_pull_policy == "Always"
    error_message = "The untagged init container image should be Always"
  }
}

# Test: the override wins over the derived policy, on every container
run "explicit_override" {
  command = plan

  variables {
    image             = "my-registry/api:v1.0.0"
    image_pull_policy = "Always"
    sidecar_containers = [
      {
        name  = "exporter"
        image = "my-registry/exporter:v2"
      },
    ]
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[0].image_pull_policy == "Always"
    error_message = "The explicit policy should override the derived one"
  }

  assert {
    condition     = kubernetes_deployment_v1.this.spec[0].template[0].spec[0].container[1].image_pull_policy == "Always"
    error_message = "The explicit policy should apply to sidecars too"
  }
}

# Test: unknown policies are rejected before reaching the API server
run "invalid_policy_rejected" {
  command = plan

  variables {
    image_pull_policy = "Sometimes"
  }

  expect_failures = [var.image_pull_policy]
}
