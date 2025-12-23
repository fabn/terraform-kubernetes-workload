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

        # Image pull secrets
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets != null ? [1] : []
          content {
            name = var.image_pull_secrets
          }
        }

        # Service account
        service_account_name = var.service_account_name

        # Pod anti-affinity
        dynamic "affinity" {
          for_each = var.anti_affinity != null ? [1] : []
          content {
            pod_anti_affinity {
              # Hard anti-affinity
              dynamic "required_during_scheduling_ignored_during_execution" {
                for_each = var.anti_affinity == "hard" ? [1] : []
                content {
                  topology_key = "kubernetes.io/hostname"
                  label_selector {
                    match_labels = local.selector_labels
                  }
                }
              }

              # Soft anti-affinity
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
  count = var.service_type != null && length(var.ports) > 0 ? 1 : 0

  metadata {
    namespace = local.namespace
    name      = var.name
    labels    = local.labels
  }

  spec {
    type     = var.service_type
    selector = local.selector_labels

    dynamic "port" {
      for_each = var.ports
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

    dynamic "tls" {
      for_each = var.ingress_tls_enabled ? [1] : []
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
