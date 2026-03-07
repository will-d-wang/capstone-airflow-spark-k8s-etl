#!/usr/bin/env bash
set -euo pipefail
eval "$(minikube docker-env)"
docker build -t local/spark-job:dev -f docker/spark/Dockerfile .
