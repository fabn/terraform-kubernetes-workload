# PDB Submodule

Standalone Pod Disruption Budget (PDB) module for Kubernetes.

## Usage

```hcl
module "pdb" {
  source = "fabn/workload/kubernetes//modules/pdb"

  namespace = "production"
  name      = "my-app-pdb"

  selector = {
    "app.kubernetes.io/name" = "my-app"
  }

  # Option 1: Minimum available pods
  min_available = "50%"

  # Option 2: Maximum unavailable pods (mutually exclusive with min_available)
  # max_unavailable = "1"

  labels = {
    "app.kubernetes.io/name" = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `namespace` | Kubernetes namespace | `string` | yes |
| `name` | PDB resource name | `string` | yes |
| `selector` | Label selector for matching pods | `map(string)` | yes |
| `labels` | Labels for the PDB | `map(string)` | no |
| `min_available` | Minimum available pods (number or %) | `string` | no |
| `max_unavailable` | Maximum unavailable pods (number or %) | `string` | no |

**Note**: Either `min_available` or `max_unavailable` should be set, not both. If neither is set, defaults to `max_unavailable = "1"`.

## Outputs

| Name | Description |
|------|-------------|
| `pdb` | The kubernetes_pod_disruption_budget_v1 resource |
| `name` | The name of the PDB |
