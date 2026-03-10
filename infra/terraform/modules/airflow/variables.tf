variable "deploy_airflow" {
  type = bool
}

variable "namespace" {
  type = string
}

variable "release_name" {
  type = string
}

variable "helm_timeout_seconds" {
  type = number
}

variable "helm_atomic" {
  type = bool
}

variable "airflow_admin_username" {
  type = string
}

variable "airflow_admin_password" {
  type      = string
  sensitive = true
}

variable "airflow_admin_email" {
  type = string
}

variable "airflow_admin_first_name" {
  type = string
}

variable "airflow_admin_last_name" {
  type = string
}
