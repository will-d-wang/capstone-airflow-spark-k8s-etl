#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-ai-core-pipeline}"
RELEASE_NAME="${RELEASE_NAME:-airflow}"
HELM_TIMEOUT="${HELM_TIMEOUT:-20m}"
HELM_RETRIES="${HELM_RETRIES:-3}"
AIRFLOW_ADMIN_USERNAME="${AIRFLOW_ADMIN_USERNAME:-admin}"
AIRFLOW_ADMIN_PASSWORD="${AIRFLOW_ADMIN_PASSWORD:-password123}"
AIRFLOW_ADMIN_EMAIL="${AIRFLOW_ADMIN_EMAIL:-admin@example.com}"
AIRFLOW_ADMIN_FIRST_NAME="${AIRFLOW_ADMIN_FIRST_NAME:-Admin}"
AIRFLOW_ADMIN_LAST_NAME="${AIRFLOW_ADMIN_LAST_NAME:-User}"

echo "Refreshing Helm repositories..."
helm repo add apache-airflow https://airflow.apache.org >/dev/null 2>&1 || true
helm repo update

if helm status "$RELEASE_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  status="$(helm status "$RELEASE_NAME" -n "$NAMESPACE" | awk -F': ' '/^STATUS:/ {print $2}')"
  if [[ "$status" == pending-* ]]; then
    echo "Release is in ${status}; attempting rollback to last deployed revision..."
    last_deployed_rev="$(helm history "$RELEASE_NAME" -n "$NAMESPACE" | awk '$0 ~ /deployed/ {rev=$1} END {print rev}')"
    if [[ -n "$last_deployed_rev" ]]; then
      helm rollback "$RELEASE_NAME" "$last_deployed_rev" -n "$NAMESPACE" --wait --timeout "$HELM_TIMEOUT" || true
    fi
  fi
fi

attempt=1
until helm upgrade --install "$RELEASE_NAME" apache-airflow/airflow \
  -n "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout "$HELM_TIMEOUT" \
  --burst-limit 200 \
  --set-string createUserJob.defaultUser.username="$AIRFLOW_ADMIN_USERNAME" \
  --set-string createUserJob.defaultUser.password="$AIRFLOW_ADMIN_PASSWORD" \
  --set-string createUserJob.defaultUser.email="$AIRFLOW_ADMIN_EMAIL" \
  --set-string createUserJob.defaultUser.firstName="$AIRFLOW_ADMIN_FIRST_NAME" \
  --set-string createUserJob.defaultUser.lastName="$AIRFLOW_ADMIN_LAST_NAME" \
  -f airflow/values.yaml; do
  if [[ "$attempt" -ge "$HELM_RETRIES" ]]; then
    echo "Helm install failed after ${HELM_RETRIES} attempts"
    exit 1
  fi
  echo "Helm install failed (attempt ${attempt}/${HELM_RETRIES}); retrying in 20s..."
  attempt=$((attempt + 1))
  sleep 20
done

echo "Waiting for Airflow components..."
if kubectl -n "$NAMESPACE" get deploy/airflow-api-server >/dev/null 2>&1; then
  kubectl -n "$NAMESPACE" rollout status deploy/airflow-api-server --timeout=10m
else
  kubectl -n "$NAMESPACE" rollout status deploy/airflow-webserver --timeout=10m
fi

kubectl -n "$NAMESPACE" rollout status deploy/airflow-scheduler --timeout=10m
if kubectl -n "$NAMESPACE" get statefulset/airflow-triggerer >/dev/null 2>&1; then
  kubectl -n "$NAMESPACE" rollout status statefulset/airflow-triggerer --timeout=10m
else
  kubectl -n "$NAMESPACE" rollout status deploy/airflow-triggerer --timeout=10m
fi
