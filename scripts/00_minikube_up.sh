#!/usr/bin/env bash
set -euo pipefail

minikube start --cpus=6 --memory=12288 --disk-size=40g
minikube addons enable ingress
minikube addons enable metrics-server

# So we can build images directly into minikube docker daemon
eval "$(minikube docker-env)"
