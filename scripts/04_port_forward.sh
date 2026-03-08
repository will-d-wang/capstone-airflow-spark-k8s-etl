#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-ai-core-pipeline}"

if kubectl -n "$NAMESPACE" get svc/airflow-api-server >/dev/null 2>&1; then
  kubectl -n "$NAMESPACE" port-forward svc/airflow-api-server 8080:8080 &
else
  kubectl -n "$NAMESPACE" port-forward svc/airflow-webserver 8080:8080 &
fi

kubectl -n "$NAMESPACE" port-forward svc/minio 9001:9001 &
echo "Airflow: http://localhost:8080"
echo "MinIO:   http://localhost:9001"
wait
