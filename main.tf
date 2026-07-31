# =============================================================================
# Datadog Integration (Optional)
# =============================================================================

module "datadog" {
  count  = var.datadog_enabled ? 1 : 0
  source = "./modules/datadog"

  container_name               = var.name
  admission_controller_enabled = var.datadog_admission_controller

  ust_tags   = var.datadog_ust_tags
  log_config = var.datadog_log_config
  checks     = var.datadog_checks
  check_id   = var.datadog_check_id
}

# =============================================================================
# SOPS Secrets (Optional)
# =============================================================================

data "sops_file" "this" {
  for_each    = local.sops_files_map
  source_file = each.value.source_file
  input_type  = each.value.input_type
}

module "sops_secret" {
  for_each = local.sops_files_map
  source   = "./modules/secret"

  namespace   = local.namespace
  name_prefix = "${var.name}-${each.key}"
  data        = data.sops_file.this[each.key].data
  labels      = local.labels
}

# =============================================================================
# Namespace (Optional)
# =============================================================================

resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.namespace
    labels = local.labels
  }
}

# =============================================================================
# Deployment
# =============================================================================

resource "kubernetes_deployment_v1" "this" {
  metadata {
    namespace   = local.namespace
    name        = var.name
    labels      = local.labels
    annotations = var.deployment_annotations
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.selector_labels
    }

    template {
      metadata {
        labels      = local.pod_labels
        annotations = local.pod_annotations
      }

      spec {
        # Main container
        container {
          name        = var.name
          image       = var.image
          command     = length(var.command) > 0 ? var.command : null
          args        = length(var.args) > 0 ? var.args : null
          working_dir = var.working_dir

          # Ports
          dynamic "port" {
            for_each = var.ports
            content {
              container_port = port.value
              name           = port.key
              protocol       = "TCP"
            }
          }

          # ConfigMap references as env
          dynamic "env_from" {
            for_each = var.config_map_refs
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }

          # Secret references as env (includes SOPS-generated secrets)
          dynamic "env_from" {
            for_each = local.all_secret_refs
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }

          # Advanced env_from with prefix
          dynamic "env_from" {
            for_each = var.env_from
            content {
              prefix = env_from.value.prefix

              dynamic "config_map_ref" {
                for_each = env_from.value.config_map != null ? [env_from.value.config_map] : []
                content {
                  name = config_map_ref.value
                }
              }

              dynamic "secret_ref" {
                for_each = env_from.value.secret != null ? [env_from.value.secret] : []
                content {
                  name = secret_ref.value
                }
              }
            }
          }

          # Plain environment variables
          dynamic "env" {
            for_each = var.envs
            content {
              name  = env.key
              value = env.value
            }
          }

          # Environment variables from secret/configmap keys
          dynamic "env" {
            for_each = var.env_value_from
            content {
              name = env.value.name

              dynamic "value_from" {
                for_each = env.value.secret_key_ref != null ? [env.value.secret_key_ref] : []
                content {
                  secret_key_ref {
                    name     = value_from.value.name
                    key      = value_from.value.key
                    optional = value_from.value.optional
                  }
                }
              }

              dynamic "value_from" {
                for_each = env.value.config_map_key_ref != null ? [env.value.config_map_key_ref] : []
                content {
                  config_map_key_ref {
                    name     = value_from.value.name
                    key      = value_from.value.key
                    optional = value_from.value.optional
                  }
                }
              }
            }
          }

          # Startup probe
          dynamic "startup_probe" {
            for_each = length(compact([var.startup_probe_path, var.http_probe_path])) > 0 ? [1] : []
            content {
              timeout_seconds   = var.startup_probe_timeout_seconds
              failure_threshold = var.startup_probe_failure_threshold
              http_get {
                path = coalesce(var.startup_probe_path, var.http_probe_path)
                port = var.probe_port
              }
            }
          }

          # Liveness probe
          dynamic "liveness_probe" {
            for_each = var.http_probe_path != null ? [1] : []
            content {
              timeout_seconds   = var.probe_timeout_seconds
              failure_threshold = var.probe_failure_threshold
              http_get {
                path = var.http_probe_path
                port = var.probe_port
              }
            }
          }

          # Readiness probe
          dynamic "readiness_probe" {
            for_each = var.http_probe_path != null ? [1] : []
            content {
              timeout_seconds   = var.probe_timeout_seconds
              failure_threshold = var.probe_failure_threshold
              http_get {
                path = var.http_probe_path
                port = var.probe_port
              }
            }
          }

          # Resource requests and limits
          resources {
            limits = {
              memory = local.memory_limit
            }
            requests = {
              cpu    = var.cpu_requests
              memory = var.memory_requests
            }
          }

          # Volume mounts
          dynamic "volume_mount" {
            for_each = var.volumes
            content {
              mount_path = volume_mount.value.mount_path
              name       = volume_mount.value.name
              sub_path   = volume_mount.value.sub_path
              read_only  = volume_mount.value.read_only
            }
          }

          # EmptyDir volume mounts
          dynamic "volume_mount" {
            for_each = var.empty_dirs
            content {
              name       = "${basename(volume_mount.value)}-empty-dir"
              mount_path = volume_mount.value
            }
          }
        }

        # Sidecar containers
        dynamic "container" {
          for_each = var.sidecar_containers
          content {
            name        = container.value.name
            image       = coalesce(container.value.image, var.image)
            command     = container.value.command
            args        = container.value.args
            working_dir = var.working_dir

            # Ports
            dynamic "port" {
              for_each = container.value.ports
              content {
                container_port = port.value
                name           = port.key
                protocol       = "TCP"
              }
            }

            # Inherit environment variables
            dynamic "env" {
              for_each = var.envs
              content {
                name  = env.key
                value = env.value
              }
            }

            # Inherit volume mounts
            dynamic "volume_mount" {
              for_each = var.volumes
              content {
                mount_path = volume_mount.value.mount_path
                name       = volume_mount.value.name
                sub_path   = volume_mount.value.sub_path
                read_only  = volume_mount.value.read_only
              }
            }

            # Inherit emptyDir mounts
            dynamic "volume_mount" {
              for_each = var.empty_dirs
              content {
                name       = "${basename(volume_mount.value)}-empty-dir"
                mount_path = volume_mount.value
              }
            }
          }
        }

        # Image pull secrets
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets != null ? [1] : []
          content {
            name = var.image_pull_secrets
          }
        }

        # Service account
        service_account_name = var.service_account_name

        # Shutdown budget for every termination path, not just voluntary ones.
        termination_grace_period_seconds = var.termination_grace_period_seconds

        # Simple exact-match node selector; complements the affinity rules below.
        node_selector = var.node_selector

        # Tolerations: node_selector/affinity only attract a pod to a node; to run
        # on a tainted dedicated pool the pod must also tolerate the taint.
        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key                = toleration.value.key
            operator           = toleration.value.operator
            value              = toleration.value.value
            effect             = toleration.value.effect
            toleration_seconds = toleration.value.toleration_seconds
          }
        }

        # Pod anti-affinity (spread), pod affinity (co-location), node affinity (placement)
        dynamic "affinity" {
          for_each = var.anti_affinity != null || var.node_affinity != null || var.pod_affinity != null || var.pod_anti_affinity != null ? [1] : []
          content {
            dynamic "pod_anti_affinity" {
              for_each = var.anti_affinity != null || var.pod_anti_affinity != null ? [1] : []
              content {
                # Hard anti-affinity shorthand (hostname spread)
                dynamic "required_during_scheduling_ignored_during_execution" {
                  for_each = var.anti_affinity == "hard" ? [1] : []
                  content {
                    topology_key = "kubernetes.io/hostname"
                    label_selector {
                      match_labels = local.selector_labels
                    }
                  }
                }

                # Raw hard anti-affinity terms (escape hatch)
                dynamic "required_during_scheduling_ignored_during_execution" {
                  for_each = var.pod_anti_affinity != null ? var.pod_anti_affinity.required : []
                  iterator = term
                  content {
                    topology_key = term.value.topology_key
                    namespaces   = term.value.namespaces
                    label_selector {
                      match_labels = term.value.match_labels
                      dynamic "match_expressions" {
                        for_each = term.value.match_expressions
                        iterator = expr
                        content {
                          key      = expr.value.key
                          operator = expr.value.operator
                          values   = expr.value.values
                        }
                      }
                    }
                  }
                }

                # Soft anti-affinity shorthand (hostname spread)
                dynamic "preferred_during_scheduling_ignored_during_execution" {
                  for_each = var.anti_affinity == "soft" ? [1] : []
                  content {
                    weight = 1
                    pod_affinity_term {
                      topology_key = "kubernetes.io/hostname"
                      label_selector {
                        match_labels = local.selector_labels
                      }
                    }
                  }
                }

                # Raw soft, weighted anti-affinity terms (escape hatch)
                dynamic "preferred_during_scheduling_ignored_during_execution" {
                  for_each = var.pod_anti_affinity != null ? var.pod_anti_affinity.preferred : []
                  iterator = term
                  content {
                    weight = term.value.weight
                    pod_affinity_term {
                      topology_key = term.value.topology_key
                      namespaces   = term.value.namespaces
                      label_selector {
                        match_labels = term.value.match_labels
                        dynamic "match_expressions" {
                          for_each = term.value.match_expressions
                          iterator = expr
                          content {
                            key      = expr.value.key
                            operator = expr.value.operator
                            values   = expr.value.values
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            dynamic "node_affinity" {
              for_each = var.node_affinity != null ? [1] : []
              content {
                # Hard constraints: all `required` expressions ANDed in one term.
                dynamic "required_during_scheduling_ignored_during_execution" {
                  for_each = length(var.node_affinity.required) > 0 ? [1] : []
                  content {
                    node_selector_term {
                      dynamic "match_expressions" {
                        for_each = var.node_affinity.required
                        iterator = expr
                        content {
                          key      = expr.value.key
                          operator = expr.value.operator
                          values   = expr.value.values
                        }
                      }
                    }
                  }
                }

                # Soft preferences: each a single weighted match expression.
                dynamic "preferred_during_scheduling_ignored_during_execution" {
                  for_each = var.node_affinity.preferred
                  iterator = pref
                  content {
                    weight = pref.value.weight
                    preference {
                      match_expressions {
                        key      = pref.value.key
                        operator = pref.value.operator
                        values   = pref.value.values
                      }
                    }
                  }
                }
              }
            }

            dynamic "pod_affinity" {
              for_each = var.pod_affinity != null ? [1] : []
              content {
                # Hard co-location terms.
                dynamic "required_during_scheduling_ignored_during_execution" {
                  for_each = var.pod_affinity.required
                  iterator = term
                  content {
                    topology_key = term.value.topology_key
                    namespaces   = term.value.namespaces
                    label_selector {
                      match_labels = term.value.match_labels
                      dynamic "match_expressions" {
                        for_each = term.value.match_expressions
                        iterator = expr
                        content {
                          key      = expr.value.key
                          operator = expr.value.operator
                          values   = expr.value.values
                        }
                      }
                    }
                  }
                }

                # Soft, weighted co-location terms.
                dynamic "preferred_during_scheduling_ignored_during_execution" {
                  for_each = var.pod_affinity.preferred
                  iterator = term
                  content {
                    weight = term.value.weight
                    pod_affinity_term {
                      topology_key = term.value.topology_key
                      namespaces   = term.value.namespaces
                      label_selector {
                        match_labels = term.value.match_labels
                        dynamic "match_expressions" {
                          for_each = term.value.match_expressions
                          iterator = expr
                          content {
                            key      = expr.value.key
                            operator = expr.value.operator
                            values   = expr.value.values
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        # Topology spread constraints (even distribution across zones/nodes).
        # label_selector defaults to the workload's own pod labels when omitted.
        dynamic "topology_spread_constraint" {
          for_each = var.topology_spread_constraints != null ? var.topology_spread_constraints : []
          iterator = tsc
          content {
            max_skew           = tsc.value.max_skew
            topology_key       = tsc.value.topology_key
            when_unsatisfiable = tsc.value.when_unsatisfiable
            min_domains        = tsc.value.min_domains
            label_selector {
              match_labels = tsc.value.label_selector == null ? local.selector_labels : tsc.value.label_selector.match_labels
              dynamic "match_expressions" {
                for_each = tsc.value.label_selector == null ? [] : tsc.value.label_selector.match_expressions
                iterator = expr
                content {
                  key      = expr.value.key
                  operator = expr.value.operator
                  values   = expr.value.values
                }
              }
            }
          }
        }

        # Volumes from secrets/configmaps/PVCs
        dynamic "volume" {
          for_each = var.volumes
          content {
            name = volume.value.name

            dynamic "secret" {
              for_each = volume.value.secret != null ? [volume.value.secret] : []
              content {
                default_mode = volume.value.mode
                secret_name  = secret.value
              }
            }

            dynamic "config_map" {
              for_each = volume.value.config_map != null ? [volume.value.config_map] : []
              content {
                name         = config_map.value
                default_mode = volume.value.mode
              }
            }

            dynamic "persistent_volume_claim" {
              for_each = volume.value.persistent_volume_claim != null ? [volume.value.persistent_volume_claim] : []
              content {
                claim_name = persistent_volume_claim.value
                read_only  = volume.value.read_only
              }
            }
          }
        }

        # EmptyDir volumes
        dynamic "volume" {
          for_each = var.empty_dirs
          content {
            name = "${basename(volume.value)}-empty-dir"
            empty_dir {}
          }
        }

        # Init container
        dynamic "init_container" {
          for_each = var.init_container != null ? [var.init_container] : []
          content {
            name        = "init"
            image       = coalesce(init_container.value.image, var.image)
            working_dir = var.working_dir
            command     = init_container.value.command
            args        = init_container.value.args

            # Inherit environment variables
            dynamic "env" {
              for_each = var.envs
              content {
                name  = env.key
                value = env.value
              }
            }

            # Inherit volume mounts
            dynamic "volume_mount" {
              for_each = var.volumes
              content {
                mount_path = volume_mount.value.mount_path
                name       = volume_mount.value.name
                sub_path   = volume_mount.value.sub_path
                read_only  = volume_mount.value.read_only
              }
            }

            # Inherit emptyDir mounts
            dynamic "volume_mount" {
              for_each = var.empty_dirs
              content {
                name       = "${basename(volume_mount.value)}-empty-dir"
                mount_path = volume_mount.value
              }
            }
          }
        }
      }
    }
  }
}

# =============================================================================
# Service (Optional)
# =============================================================================

resource "kubernetes_service_v1" "this" {
  count = var.service_type != null && length(local.all_ports) > 0 ? 1 : 0

  metadata {
    namespace = local.namespace
    name      = var.name
    labels    = local.labels
  }

  spec {
    type     = var.service_type
    selector = local.selector_labels

    dynamic "port" {
      for_each = local.all_ports
      content {
        name        = port.key
        port        = port.value
        target_port = port.value
      }
    }
  }
}

# =============================================================================
# Ingress (Optional)
# =============================================================================

resource "kubernetes_ingress_v1" "this" {
  count                  = length(var.ingress_hostnames) > 0 ? 1 : 0
  wait_for_load_balancer = true

  metadata {
    namespace   = local.namespace
    name        = var.name
    annotations = local.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = var.ingress_hostnames
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service_v1.this[0].metadata[0].name
                port {
                  name = keys(var.ports)[0]
                }
              }
            }
          }
        }
      }
    }

    # No in-cluster TLS on ALB: termination happens on the load balancer
    dynamic "tls" {
      for_each = var.ingress_tls_enabled && var.alb == null ? [1] : []
      content {
        hosts       = var.ingress_hostnames
        secret_name = local.tls_secret_name
      }
    }
  }
}

# =============================================================================
# HPA (Optional)
# =============================================================================

module "hpa" {
  count  = var.hpa_enabled && var.hpa_config != null ? 1 : 0
  source = "./modules/hpa"

  namespace = local.namespace
  name      = var.name
  labels    = local.labels

  target_ref = {
    api_version = "apps/v1"
    kind        = "Deployment"
    name        = kubernetes_deployment_v1.this.metadata[0].name
  }

  min_replicas = var.hpa_config.min_replicas
  max_replicas = var.hpa_config.max_replicas
  metrics      = var.hpa_config.metrics
}

# =============================================================================
# PDB (Optional)
# =============================================================================

module "pdb" {
  count  = var.pdb_enabled ? 1 : 0
  source = "./modules/pdb"

  namespace       = local.namespace
  name            = var.name
  labels          = local.labels
  selector        = local.selector_labels
  min_available   = var.pdb_config != null ? var.pdb_config.min_available : null
  max_unavailable = var.pdb_config != null ? var.pdb_config.max_unavailable : "1"
}

# =============================================================================
# ServiceMonitor (Optional)
# =============================================================================

module "service_monitor" {
  count  = var.service_monitor_enabled && length(var.ports) > 0 ? 1 : 0
  source = "./modules/service-monitor"

  namespace = local.namespace
  name      = var.name
  labels    = local.labels
  selector  = local.selector_labels

  endpoints = [{
    port     = var.service_monitor_config != null ? var.service_monitor_config.port : "metrics"
    path     = var.service_monitor_config != null ? var.service_monitor_config.path : "/metrics"
    interval = var.service_monitor_config != null ? var.service_monitor_config.interval : "30s"
  }]
}
