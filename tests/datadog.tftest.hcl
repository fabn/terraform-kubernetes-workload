# =============================================================================
# Datadog Integration Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No Datadog by default
run "no_datadog_by_default" {
  command = plan

  assert {
    condition     = length(module.datadog) == 0
    error_message = "Datadog module should not be created by default"
  }
}

# Test: Datadog enabled
run "datadog_enabled" {
  command = plan

  variables {
    datadog_enabled = true
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created when enabled"
  }
}

# Test: Datadog with UST tags
run "datadog_ust_tags" {
  command = plan

  variables {
    datadog_enabled = true
    datadog_ust_tags = {
      service = "my-api"
      env     = "production"
      version = "v1.0.0"
      team    = "platform"
    }
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created with UST tags"
  }
}

# Test: Datadog with log config
run "datadog_log_config" {
  command = plan

  variables {
    datadog_enabled = true
    datadog_log_config = {
      source  = "ruby"
      service = "my-api"
    }
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created with log config"
  }
}

# Test: Datadog log exclusion with log_processing_rules format
run "datadog_log_exclusion" {
  command = plan

  variables {
    datadog_enabled = true
    datadog_log_config = {
      source  = "oauth2-proxy"
      service = "my-app"
      exclude = ["/robots.txt", "/health"]
    }
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created with log exclusion"
  }

  # Verify the annotation contains log_processing_rules (container_name = var.name = "test-app")
  assert {
    condition     = can(regex("log_processing_rules", module.datadog[0].pod_annotations["ad.datadoghq.com/test-app.logs"]))
    error_message = "Log annotation should contain log_processing_rules"
  }

  # Verify the annotation contains exclude_at_match type
  assert {
    condition     = can(regex("exclude_at_match", module.datadog[0].pod_annotations["ad.datadoghq.com/test-app.logs"]))
    error_message = "Log processing rules should have exclude_at_match type"
  }
}

# Test: Datadog admission controller disabled
run "datadog_admission_controller_disabled" {
  command = plan

  variables {
    datadog_enabled              = true
    datadog_admission_controller = false
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created even with admission controller disabled"
  }
}

# Test: Datadog with check ID
run "datadog_check_id" {
  command = plan

  variables {
    datadog_enabled  = true
    datadog_check_id = "postgres"
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created with check ID"
  }
}

# Test: Datadog with custom checks (AD v2 format)
run "datadog_custom_checks" {
  command = plan

  variables {
    datadog_enabled = true
    datadog_checks = {
      my_custom_check = {
        instances = [
          {
            host = "%%host%%"
            port = 9090
          }
        ]
      }
    }
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created with custom checks"
  }

  # Verify v2 format annotation exists
  assert {
    condition     = can(module.datadog[0].pod_annotations["ad.datadoghq.com/test-app.checks"])
    error_message = "Should generate .checks annotation (v2 format)"
  }
}

# Test: Datadog checks v2 format validation
run "datadog_checks_v2_format" {
  command = plan

  variables {
    datadog_enabled = true
    datadog_checks = {
      mysql = {
        instances = [
          { host = "db.example.com", port = 3306 }
        ]
      }
    }
  }

  assert {
    condition     = length(module.datadog) == 1
    error_message = "Datadog module should be created with v2 checks"
  }

  # Verify annotation contains instances (init_config omitted when empty)
  assert {
    condition     = can(regex("instances", module.datadog[0].pod_annotations["ad.datadoghq.com/test-app.checks"]))
    error_message = "Checks annotation should contain instances"
  }

  # Verify init_config is NOT present when empty
  assert {
    condition     = !can(regex("init_config", module.datadog[0].pod_annotations["ad.datadoghq.com/test-app.checks"]))
    error_message = "Checks annotation should NOT contain init_config when empty"
  }

  # Verify the check name appears in the annotation
  assert {
    condition     = can(regex("mysql", module.datadog[0].pod_annotations["ad.datadoghq.com/test-app.checks"]))
    error_message = "Checks annotation should contain the check name 'mysql'"
  }
}
