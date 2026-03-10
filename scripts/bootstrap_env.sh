#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/deploy_infra/config.sh"
source "${ROOT_DIR}/scripts/libs/deploy_infra/helpers.sh"
source "${ROOT_DIR}/scripts/libs/deploy_infra/post_apply.sh"

main() {
  require_command kubectl
  require_command minikube
  require_command curl
  require_command envsubst

  run_seed_data_job_normalized="$(normalize_bool "$RUN_SEED_DATA_JOB")"
  configure_local_access_normalized="$(normalize_bool "$CONFIGURE_LOCAL_ACCESS")"

  wait_for_rollout

  if [[ "$run_seed_data_job_normalized" == "true" ]]; then
    run_seed_data_job
  fi

  if [[ "$configure_local_access_normalized" == "true" ]]; then
    configure_local_access
  fi
}

main "$@"
