# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Terraform module for deploying Kubernetes workloads. Published on Terraform Registry as `fabn/workload/kubernetes`.

This module provides a comprehensive solution for deploying applications to Kubernetes with:
- Kubernetes Deployment with full pod spec configuration
- Optional Service (ClusterIP/LoadBalancer/NodePort)
- Optional Ingress with TLS and canary deployment support
- Standalone submodules for HPA, PDB, ServiceMonitor, and Datadog integration

## Commands

### Terraform Operations

```bash
# Format check (recursive)
terraform fmt -check -recursive

# Format files
terraform fmt -recursive

# Initialize module
terraform init

# Validate terraform
terraform validate

# Run tests
terraform test

# Run specific test
terraform test -filter=tests/deployment.tftest.hcl
```

### Git Hooks (Lefthook)

```bash
# Install hooks
lefthook install

# Run all validations manually
lefthook run validate-all

# Pre-commit runs: actionlint, terraform fmt (with auto-fix)
# Pre-push runs: actionlint, terraform fmt -check, terraform validate
```

## Architecture

### Module Structure

```
.
├── main.tf              # Core resources (Deployment, Service, Ingress)
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider requirements
├── locals.tf            # Computed values
│
├── modules/
│   ├── hpa/             # Standalone Horizontal Pod Autoscaler
│   ├── pdb/             # Standalone Pod Disruption Budget
│   ├── service-monitor/ # Standalone Prometheus ServiceMonitor
│   └── datadog/         # Datadog integration helper (labels + annotations)
│
├── examples/            # Usage examples
│   ├── minimal/
│   ├── with-service/
│   ├── with-ingress/
│   ├── full-featured/
│   ├── with-datadog/
│   ├── standalone-hpa/
│   └── standalone-pdb/
│
└── tests/               # Terraform tests
```

### Key Features

- **Deployment**: Full Kubernetes Deployment with probes, resources, volumes, init containers
- **Service**: Optional ClusterIP/LoadBalancer service
- **Ingress**: Optional ingress with TLS (ACME) and canary deployment support
- **HPA**: Horizontal Pod Autoscaler with custom metrics support
- **PDB**: Pod Disruption Budget for high availability
- **ServiceMonitor**: Prometheus monitoring integration
- **Datadog**: UST tags, log annotations, check annotations, admission controller label

### Datadog Integration

When `datadog_enabled = true`:
- Adds UST labels (tags.datadoghq.com/service, env, version)
- Adds log annotations for Datadog log collection
- Adds `admission.datadoghq.com/enabled: "true"` **label** (not annotation!) for automatic env injection
- Supports Datadog checks autodiscovery

## MCP Servers

This repository has MCP servers configured in `.mcp.json`:

- **awslabs.terraform-mcp-server** - Terraform operations and documentation
- **mcp-server-git** - Git operations
- **filesystem** - File operations

## Testing

Tests use the Terraform native testing framework with Kind (Kubernetes in Docker) clusters.

```bash
# Run all tests
terraform test

# Run specific test file
terraform test -filter=tests/deployment.tftest.hcl
```

## CI/CD

- **GitHub Actions** - Automated testing with Kind clusters
- **Release Drafter** - Automatic release notes generation
- **Dependabot** - Dependency updates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Run `lefthook run validate-all`
5. Submit a pull request
