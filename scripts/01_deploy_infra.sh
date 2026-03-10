#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/deploy_infra/config.sh"
source "${ROOT_DIR}/scripts/libs/deploy_infra/helpers.sh"
source "${ROOT_DIR}/scripts/libs/deploy_infra/terraform.sh"

main() {
  require_command terraform
  require_command minikube
  require_command docker

  timeout_seconds="$(to_seconds "$HELM_TIMEOUT")"
  helm_atomic_normalized="$(normalize_bool "$HELM_ATOMIC")"
  skip_bootstrap_normalized="$(normalize_bool "$SKIP_BOOTSTRAP")"

  ensure_airflow_image_exists

  terraform_init
  terraform_apply_infra

  if [[ "$skip_bootstrap_normalized" == "false" ]]; then
    "${ROOT_DIR}/scripts/bootstrap_env.sh"
  fi
}

main "$@"
