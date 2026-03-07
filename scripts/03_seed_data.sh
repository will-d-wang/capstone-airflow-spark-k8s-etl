#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f infra/k8s/init/seed-raw-data-job.yaml
kubectl -n ai-core-pipeline wait --for=condition=complete job/seed-raw-data --timeout=120s
