terraform_init() {
  echo "Initializing Terraform in ${TERRAFORM_DIR} ..."
  terraform -chdir="$TERRAFORM_DIR" init -input=false >/dev/null
}

terraform_apply_infra() {
  terraform -chdir="$TERRAFORM_DIR" apply -input=false -auto-approve \
    -var="kube_context=${PROFILE}" \
    -var="namespace=${NAMESPACE}" \
    -var="release_name=${RELEASE_NAME}" \
    -var="deploy_airflow=true" \
    -var="helm_timeout_seconds=${timeout_seconds}" \
    -var="helm_atomic=${helm_atomic_normalized}" \
    -var="postgres_user=${POSTGRES_USER}" \
    -var="postgres_password=${POSTGRES_PASSWORD}" \
    -var="postgres_db=${POSTGRES_DB}" \
    -var="minio_root_user=${MINIO_ROOT_USER}" \
    -var="minio_root_password=${MINIO_ROOT_PASSWORD}" \
    -var="airflow_admin_username=${AIRFLOW_ADMIN_USERNAME}" \
    -var="airflow_admin_password=${AIRFLOW_ADMIN_PASSWORD}" \
    -var="airflow_admin_email=${AIRFLOW_ADMIN_EMAIL}" \
    -var="airflow_admin_first_name=${AIRFLOW_ADMIN_FIRST_NAME}" \
    -var="airflow_admin_last_name=${AIRFLOW_ADMIN_LAST_NAME}"
}
