variable "kubeconfig_path" {
  description = "Path to kubeconfig file."
  type        = string
  default     = ""
}

variable "kube_context" {
  description = "Kubeconfig context/profile to target."
  type        = string
  default     = "ai-core-etl"
}

variable "namespace" {
  description = "Namespace for pipeline resources."
  type        = string
  default     = "ai-core-pipeline"
}

variable "release_name" {
  description = "Helm release name for Airflow."
  type        = string
  default     = "airflow"
}

variable "deploy_airflow" {
  description = "Whether to deploy Airflow Helm release and its ingress."
  type        = bool
  default     = false
}

variable "helm_timeout_seconds" {
  description = "Helm release timeout in seconds."
  type        = number
  default     = 1200
}

variable "helm_atomic" {
  description = "Whether Helm should roll back/uninstall the release on failure."
  type        = bool
  default     = true
}

variable "postgres_user" {
  description = "Postgres username."
  type        = string
  default     = "airflow"
}

variable "postgres_password" {
  description = "Postgres password."
  type        = string
  default     = "airflow"
  sensitive   = true
}

variable "postgres_db" {
  description = "Postgres database name."
  type        = string
  default     = "airflow"
}

variable "postgres_storage" {
  description = "PVC size for Postgres data."
  type        = string
  default     = "5Gi"
}

variable "minio_root_user" {
  description = "MinIO root username."
  type        = string
  default     = "minioadmin"
}

variable "minio_root_password" {
  description = "MinIO root password."
  type        = string
  default     = "minioadmin123"
  sensitive   = true
}

variable "minio_storage" {
  description = "PVC size for MinIO data."
  type        = string
  default     = "10Gi"
}

variable "airflow_db_protocol" {
  description = "Protocol for Airflow metadata DB connection."
  type        = string
  default     = "postgresql"
}

variable "airflow_db_port" {
  description = "Port for Airflow metadata DB connection."
  type        = number
  default     = 5432
}

variable "airflow_db_sslmode" {
  description = "SSL mode for Airflow metadata DB connection."
  type        = string
  default     = "disable"
}

variable "s3_bucket" {
  description = "Bucket used by Spark jobs."
  type        = string
  default     = "lake"
}

variable "aws_default_region" {
  description = "Default AWS region for S3-compatible clients."
  type        = string
  default     = "us-east-1"
}

variable "airflow_admin_username" {
  description = "Airflow default admin username."
  type        = string
  default     = "admin"
}

variable "airflow_admin_password" {
  description = "Airflow default admin password."
  type        = string
  default     = "password123"
  sensitive   = true
}

variable "airflow_admin_email" {
  description = "Airflow default admin email."
  type        = string
  default     = "admin@example.com"
}

variable "airflow_admin_first_name" {
  description = "Airflow default admin first name."
  type        = string
  default     = "Admin"
}

variable "airflow_admin_last_name" {
  description = "Airflow default admin last name."
  type        = string
  default     = "User"
}
