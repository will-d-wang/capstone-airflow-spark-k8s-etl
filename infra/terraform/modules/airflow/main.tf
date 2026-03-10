resource "helm_release" "airflow" {
  count = var.deploy_airflow ? 1 : 0

  name             = var.release_name
  repository       = "https://airflow.apache.org"
  chart            = "airflow"
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = var.helm_timeout_seconds
  atomic           = var.helm_atomic
  cleanup_on_fail  = true

  values = [file("${path.root}/../../airflow/helm-values.yaml")]

  set {
    name  = "createUserJob.defaultUser.username"
    value = var.airflow_admin_username
  }

  set_sensitive {
    name  = "createUserJob.defaultUser.password"
    value = var.airflow_admin_password
  }

  set {
    name  = "createUserJob.defaultUser.email"
    value = var.airflow_admin_email
  }

  set {
    name  = "createUserJob.defaultUser.firstName"
    value = var.airflow_admin_first_name
  }

  set {
    name  = "createUserJob.defaultUser.lastName"
    value = var.airflow_admin_last_name
  }
}

resource "kubernetes_ingress_v1" "airflow" {
  count = var.deploy_airflow ? 1 : 0

  depends_on = [helm_release.airflow]

  metadata {
    name      = "airflow"
    namespace = var.namespace
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "airflow.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "airflow-api-server"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
