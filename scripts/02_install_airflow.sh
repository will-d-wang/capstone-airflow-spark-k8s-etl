#!/usr/bin/env bash
set -euo pipefail

helm upgrade --install airflow apache-airflow/airflow \
  -n ai-core-pipeline \
  -f infra/airflow/values.yaml

kubectl -n ai-core-pipeline rollout status deploy/airflow-webserver
kubectl -n ai-core-pipeline rollout status deploy/airflow-scheduler
kubectl -n ai-core-pipeline rollout status deploy/airflow-triggerer
