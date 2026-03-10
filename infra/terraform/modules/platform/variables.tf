variable "namespace" {
  type = string
}

variable "postgres_user" {
  type = string
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "postgres_db" {
  type = string
}

variable "postgres_storage" {
  type = string
}

variable "minio_root_user" {
  type = string
}

variable "minio_root_password" {
  type      = string
  sensitive = true
}

variable "minio_storage" {
  type = string
}

variable "airflow_db_protocol" {
  type = string
}

variable "airflow_db_port" {
  type = number
}

variable "airflow_db_sslmode" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "aws_default_region" {
  type = string
}
