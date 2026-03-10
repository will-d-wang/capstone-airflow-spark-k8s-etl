locals {
  kubeconfig_path = var.kubeconfig_path != "" ? var.kubeconfig_path : pathexpand("~/.kube/config")
}

provider "kubernetes" {
  config_path    = local.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = local.kubeconfig_path
    config_context = var.kube_context
  }
}

module "platform" {
  source = "./modules/platform"

  namespace           = var.namespace
  postgres_user       = var.postgres_user
  postgres_password   = var.postgres_password
  postgres_db         = var.postgres_db
  postgres_storage    = var.postgres_storage
  minio_root_user     = var.minio_root_user
  minio_root_password = var.minio_root_password
  minio_storage       = var.minio_storage
  airflow_db_protocol = var.airflow_db_protocol
  airflow_db_port     = var.airflow_db_port
  airflow_db_sslmode  = var.airflow_db_sslmode
  s3_bucket           = var.s3_bucket
  aws_default_region  = var.aws_default_region
}

module "airflow" {
  source = "./modules/airflow"

  depends_on = [module.platform]

  deploy_airflow           = var.deploy_airflow
  namespace                = module.platform.namespace
  release_name             = var.release_name
  helm_timeout_seconds     = var.helm_timeout_seconds
  helm_atomic              = var.helm_atomic
  airflow_admin_username   = var.airflow_admin_username
  airflow_admin_password   = var.airflow_admin_password
  airflow_admin_email      = var.airflow_admin_email
  airflow_admin_first_name = var.airflow_admin_first_name
  airflow_admin_last_name  = var.airflow_admin_last_name
}
