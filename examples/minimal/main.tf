# =============================================================================
# Minimal Example
# =============================================================================
# This example shows the simplest possible deployment using the module.
# Only the required variables are specified.

module "app" {
  source = "../.."

  namespace = "default"
  name      = "my-app"
  image     = "nginx:latest"
}
