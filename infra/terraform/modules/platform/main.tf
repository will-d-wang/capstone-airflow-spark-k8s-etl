locals {
  airflow_db_host = "postgres.${var.namespace}.svc.cluster.local"
  s3_endpoint     = "http://minio.${var.namespace}.svc.cluster.local:9000"
  airflow_metadata_connection = format(
    "%s://%s:%s@%s:%d/%s?sslmode=%s",
    var.airflow_db_protocol,
    var.postgres_user,
    var.postgres_password,
    local.airflow_db_host,
    var.airflow_db_port,
    var.postgres_db,
    var.airflow_db_sslmode
  )
}

resource "kubernetes_namespace_v1" "pipeline" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "pipeline_secrets" {
  metadata {
    name      = "pipeline-secrets"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  data = {
    POSTGRES_USER       = var.postgres_user
    POSTGRES_PASSWORD   = var.postgres_password
    POSTGRES_DB         = var.postgres_db
    MINIO_ROOT_USER     = var.minio_root_user
    MINIO_ROOT_PASSWORD = var.minio_root_password
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "airflow_metadata_secret" {
  metadata {
    name      = "airflow-metadata-secret"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  data = {
    connection = local.airflow_metadata_connection
  }

  type = "Opaque"
}

resource "kubernetes_config_map_v1" "pipeline_config" {
  metadata {
    name      = "pipeline-config"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  data = {
    S3_ENDPOINT        = local.s3_endpoint
    S3_BUCKET          = var.s3_bucket
    AWS_DEFAULT_REGION = var.aws_default_region
  }
}

resource "kubernetes_service_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    service_name = kubernetes_service_v1.postgres.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15"

          port {
            container_port = 5432
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.pipeline_secrets.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.pipeline_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.pipeline_secrets.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "pgdata"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "pgdata"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = var.postgres_storage
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "minio_data" {
  metadata {
    name      = "minio-pvc"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.minio_storage
      }
    }
  }
}

resource "kubernetes_deployment_v1" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        container {
          name  = "minio"
          image = "quay.io/minio/minio:RELEASE.2024-01-16T16-07-38Z"
          args  = ["server", "/data", "--console-address", ":9001"]

          port {
            container_port = 9000
          }

          port {
            container_port = 9001
          }

          env {
            name = "MINIO_ROOT_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.pipeline_secrets.metadata[0].name
                key  = "MINIO_ROOT_USER"
              }
            }
          }

          env {
            name = "MINIO_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.pipeline_secrets.metadata[0].name
                key  = "MINIO_ROOT_PASSWORD"
              }
            }
          }

          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.minio_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    selector = {
      app = "minio"
    }

    port {
      name        = "api"
      port        = 9000
      target_port = 9000
    }

    port {
      name        = "console"
      port        = 9001
      target_port = 9001
    }
  }
}

resource "kubernetes_ingress_v1" "minio_console" {
  metadata {
    name      = "minio-console"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "minio-console.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.minio.metadata[0].name
              port {
                name = "console"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "minio_api" {
  metadata {
    name      = "minio-api"
    namespace = kubernetes_namespace_v1.pipeline.metadata[0].name
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "minio-api.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.minio.metadata[0].name
              port {
                name = "api"
              }
            }
          }
        }
      }
    }
  }
}
