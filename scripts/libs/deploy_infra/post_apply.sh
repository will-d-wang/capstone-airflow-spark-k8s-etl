wait_for_rollout() {
  echo "Waiting for Postgres rollout..."
  kubectl -n "$NAMESPACE" rollout status statefulset/postgres
  echo "Waiting for MinIO rollout..."
  kubectl -n "$NAMESPACE" rollout status deploy/minio
  echo "Waiting for Airflow scheduler rollout..."
  kubectl -n "$NAMESPACE" rollout status deploy/airflow-scheduler
}

run_seed_data_job() {
  local job_name="seed-raw-data-cli"
  local s3_endpoint="http://minio.${NAMESPACE}.svc.cluster.local:9000"
  local manifest_template="${ROOT_DIR}/infra/k8s/seed-raw-data-job.yaml"
  local manifest_rendered

  if [[ ! -f "$manifest_template" ]]; then
    echo "Missing manifest template: ${manifest_template}"
    exit 1
  fi

  echo "Running seed data job ${job_name}..."
  manifest_rendered="$(mktemp)"
  kubectl -n "$NAMESPACE" delete job "$job_name" --ignore-not-found >/dev/null 2>&1 || true
  JOB_NAME="$job_name" \
  NAMESPACE="$NAMESPACE" \
  S3_ENDPOINT="$s3_endpoint" \
  S3_BUCKET="$S3_BUCKET" \
  DOLLAR='$' \
  envsubst < "$manifest_template" > "$manifest_rendered"
  kubectl apply -f "$manifest_rendered"

  kubectl -n "$NAMESPACE" wait --for=condition=complete --timeout=180s job/"$job_name"
  echo "Seed data job logs:"
  kubectl -n "$NAMESPACE" logs job/"$job_name"
  rm -f "$manifest_rendered"
}

hosts_file_has_local_entries() {
  local minikube_ip
  minikube_ip="$1"

  [[ -f "$HOSTS_FILE" ]] && awk -v ip="$minikube_ip" '
    $1 == ip {
      for (i = 2; i <= NF; i++) {
        if ($i == "airflow.local") airflow = 1
        if ($i == "minio-console.local") minio_console = 1
        if ($i == "minio-api.local") minio_api = 1
      }
    }
    END { exit !(airflow && minio_console && minio_api) }
  ' "$HOSTS_FILE"
}

write_hosts_file() {
  local rendered_hosts_file
  rendered_hosts_file="$1"

  if [[ -w "$HOSTS_FILE" ]] || ([[ ! -e "$HOSTS_FILE" ]] && [[ -w "$(dirname "$HOSTS_FILE")" ]]); then
    cat "$rendered_hosts_file" > "$HOSTS_FILE"
    echo "Hosts file updated."
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "$(dirname "$HOSTS_FILE")"
    sudo tee "$HOSTS_FILE" >/dev/null < "$rendered_hosts_file"
    echo "Hosts file updated via sudo."
    return
  fi

  return 1
}

ensure_hosts_file_entries() {
  local minikube_ip
  local hosts_line
  local tmp_hosts
  local write_failed=0

  minikube_ip="$1"
  hosts_line="${minikube_ip} airflow.local minio-console.local minio-api.local"
  tmp_hosts="$(mktemp)"

  if hosts_file_has_local_entries "$minikube_ip"; then
    echo "Hosts file already configured for ${minikube_ip}; skipping update."
    rm -f "$tmp_hosts"
    return
  fi

  if [[ -f "$HOSTS_FILE" ]]; then
    awk '!/airflow\.local|minio-console\.local|minio-api\.local/' "$HOSTS_FILE" > "$tmp_hosts"
  fi
  echo "$hosts_line" >> "$tmp_hosts"

  if ! write_hosts_file "$tmp_hosts"; then
    write_failed=1
  fi

  rm -f "$tmp_hosts"

  if (( write_failed )); then
    echo "Could not write ${HOSTS_FILE} automatically (no permissions and no sudo)."
    echo "Add this line manually:"
    echo "$hosts_line"
  fi
}

verify_ingress_resources() {
  kubectl -n "$NAMESPACE" get ingress airflow minio-console minio-api >/dev/null
}

wait_for_minio_health() {
  local attempt=1
  local status_code=""

  while (( attempt <= MINIO_HEALTH_RETRIES )); do
    status_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$MINIO_HEALTH_URL" || true)"
    if [[ "$status_code" == "200" ]]; then
      echo "MinIO API health check passed (HTTP 200)."
      break
    fi

    if (( attempt == MINIO_HEALTH_RETRIES )); then
      echo "MinIO API health check failed after ${MINIO_HEALTH_RETRIES} attempts (last HTTP ${status_code:-N/A})."
      exit 1
    fi

    echo "MinIO API not ready yet (attempt ${attempt}/${MINIO_HEALTH_RETRIES}, HTTP ${status_code:-N/A}); retrying in ${MINIO_HEALTH_INTERVAL_SECONDS}s..."
    attempt=$((attempt + 1))
    sleep "$MINIO_HEALTH_INTERVAL_SECONDS"
  done
}

print_local_access_endpoints() {
  echo "Airflow:       http://airflow.local"
  echo "MinIO Console: http://minio-console.local"
  echo "MinIO API:     http://minio-api.local"
}

configure_local_access() {
  local minikube_ip

  echo "Configuring local access..."
  unset DOCKER_API_VERSION || true

  minikube_ip="$(minikube -p "$PROFILE" ip)"

  ensure_hosts_file_entries "$minikube_ip"
  verify_ingress_resources
  wait_for_minio_health
  print_local_access_endpoints
}
