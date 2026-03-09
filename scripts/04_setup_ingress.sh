#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-ai-core-pipeline}"
PROFILE="${MINIKUBE_PROFILE:-ai-core-etl}"
HOSTS_FILE="${HOSTS_FILE:-/etc/hosts}"
HOSTS_DOMAINS=(airflow.local minio-console.local minio-api.local)

echo "Applying ingress manifests..."
kubectl apply -f k8s/ingress-minio.yaml >/dev/null
kubectl apply -f k8s/ingress-airflow-api.yaml >/dev/null

MINIKUBE_IP="$(minikube -p "$PROFILE" ip)"

HOSTS_LINE="${MINIKUBE_IP} ${HOSTS_DOMAINS[*]}"
TMP_HOSTS="$(mktemp)"

cleanup() {
  rm -f "$TMP_HOSTS"
}
trap cleanup EXIT

if [[ -f "$HOSTS_FILE" ]]; then
  awk '!/airflow\.local|minio-console\.local|minio-api\.local/' "$HOSTS_FILE" > "$TMP_HOSTS"
fi
echo "$HOSTS_LINE" >> "$TMP_HOSTS"

echo
echo "Updating hosts file: ${HOSTS_FILE}"
if [[ -w "$HOSTS_FILE" ]] || ([[ ! -e "$HOSTS_FILE" ]] && [[ -w "$(dirname "$HOSTS_FILE")" ]]); then
  cat "$TMP_HOSTS" > "$HOSTS_FILE"
  echo "Hosts file updated."
elif command -v sudo >/dev/null 2>&1; then
  sudo mkdir -p "$(dirname "$HOSTS_FILE")"
  sudo tee "$HOSTS_FILE" >/dev/null < "$TMP_HOSTS"
  echo "Hosts file updated via sudo."
else
  echo "Could not write ${HOSTS_FILE} automatically (no permissions and no sudo)."
  echo "Add this line manually:"
  echo "$HOSTS_LINE"
fi

echo
echo "Airflow:       http://airflow.local"
echo "MinIO Console: http://minio-console.local"
echo "MinIO API:     http://minio-api.local"
