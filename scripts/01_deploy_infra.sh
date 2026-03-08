#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-ai-core-pipeline}"

# Core infra secrets (override via env vars for demo/CI usage)
POSTGRES_USER="${POSTGRES_USER:-airflow}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-airflow}"
POSTGRES_DB="${POSTGRES_DB:-airflow}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin123}"

# Airflow metadata DB connection secret (used by Helm chart via metadataSecretName)
AIRFLOW_DB_PROTOCOL="${AIRFLOW_DB_PROTOCOL:-postgresql}"
AIRFLOW_DB_HOST="${AIRFLOW_DB_HOST:-postgres.${NAMESPACE}.svc.cluster.local}"
AIRFLOW_DB_PORT="${AIRFLOW_DB_PORT:-5432}"
AIRFLOW_DB_NAME="${AIRFLOW_DB_NAME:-$POSTGRES_DB}"
AIRFLOW_DB_USER="${AIRFLOW_DB_USER:-$POSTGRES_USER}"
AIRFLOW_DB_PASSWORD="${AIRFLOW_DB_PASSWORD:-$POSTGRES_PASSWORD}"
AIRFLOW_DB_SSLMODE="${AIRFLOW_DB_SSLMODE:-disable}"

AIRFLOW_METADATA_CONNECTION="${AIRFLOW_DB_PROTOCOL}://${AIRFLOW_DB_USER}:${AIRFLOW_DB_PASSWORD}@${AIRFLOW_DB_HOST}:${AIRFLOW_DB_PORT}/${AIRFLOW_DB_NAME}?sslmode=${AIRFLOW_DB_SSLMODE}"

kubectl apply -f infra/k8s/namespace.yaml

kubectl -n "$NAMESPACE" create secret generic pipeline-secrets \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_DB="$POSTGRES_DB" \
  --from-literal=MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  --from-literal=MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic airflow-metadata-secret \
  --from-literal=connection="$AIRFLOW_METADATA_CONNECTION" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n "$NAMESPACE" -f infra/k8s/configmap.yaml
kubectl apply -f infra/k8s/postgres.yaml
kubectl apply -f infra/k8s/minio.yaml

kubectl -n "$NAMESPACE" rollout status statefulset/postgres
kubectl -n "$NAMESPACE" rollout status deploy/minio
