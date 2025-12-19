# =============================================================================
# Standalone PDB Example
# =============================================================================
# This example shows how to use the PDB submodule independently,
# for example to add disruption budget to an existing deployment.

module "pdb" {
  source = "../../modules/pdb"

  namespace = "production"
  name      = "existing-deployment-pdb"

  # Selector to match pods
  selector = {
    "app.kubernetes.io/name" = "existing-deployment"
  }

  # PDB can be configured with either min_available OR max_unavailable
  # Option 1: Minimum available pods (can be number or percentage)
  min_available = "50%"

  # Option 2: Maximum unavailable pods (uncomment and comment min_available)
  # max_unavailable = "1"

  # Labels
  labels = {
    "app.kubernetes.io/name"       = "existing-deployment"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}
