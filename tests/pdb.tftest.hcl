# =============================================================================
# PDB Tests
# =============================================================================

mock_provider "kubernetes" {}

variables {
  namespace = "test-ns"
  name      = "test-app"
  image     = "nginx:latest"
}

# Test: No PDB by default
run "no_pdb_by_default" {
  command = plan

  assert {
    condition     = length(module.pdb) == 0
    error_message = "PDB should not be created by default"
  }
}

# Test: PDB enabled
run "pdb_enabled" {
  command = plan

  variables {
    pdb_enabled = true
  }

  assert {
    condition     = length(module.pdb) == 1
    error_message = "PDB should be created when enabled"
  }
}

# Test: PDB with min_available
run "pdb_min_available" {
  command = plan

  variables {
    pdb_enabled = true
    pdb_config = {
      min_available = "50%"
    }
  }

  assert {
    condition     = length(module.pdb) == 1
    error_message = "PDB should be created with min_available"
  }
}

# Test: PDB with max_unavailable
run "pdb_max_unavailable" {
  command = plan

  variables {
    pdb_enabled = true
    pdb_config = {
      max_unavailable = "1"
    }
  }

  assert {
    condition     = length(module.pdb) == 1
    error_message = "PDB should be created with max_unavailable"
  }
}
