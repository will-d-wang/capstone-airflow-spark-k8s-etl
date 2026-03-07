#!/usr/bin/env bash
set -euo pipefail

kubectl -n ai-core-pipeline port-forward svc/airflow-webserver 8080:8080 &
kubectl -n ai-core-pipeline port-forward svc/minio 9001:9001 &
echo "Airflow: http://localhost:8080 (admin/admin)"
echo "MinIO:   http://localhost:9001 (minioadmin/minioadmin123)"
wait
