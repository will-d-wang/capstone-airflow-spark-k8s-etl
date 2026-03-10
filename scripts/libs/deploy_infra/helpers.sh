require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "${cmd} is required but not installed."
    exit 1
  fi
}

normalize_bool() {
  local value="${1,,}"
  case "$value" in
    true|false) echo "$value" ;;
    *)
      echo "Invalid boolean value: ${1} (expected true|false)"
      exit 1
      ;;
  esac
}

to_seconds() {
  local value="${1,,}"
  local num
  local unit
  if [[ "$value" =~ ^([0-9]+)(ms|s|m|h)?$ ]]; then
    num="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
  else
    echo "Invalid HELM_TIMEOUT value: ${1}"
    exit 1
  fi

  case "$unit" in
    ms) echo $((num / 1000 > 0 ? num / 1000 : 1)) ;;
    s|"") echo "$num" ;;
    m) echo $((num * 60)) ;;
    h) echo $((num * 3600)) ;;
    *)
      echo "Unsupported HELM_TIMEOUT unit in value: ${1}"
      exit 1
      ;;
  esac
}

ensure_airflow_image_exists() {
  local max_api_version
  local docker_api_version=""

  eval "$(minikube -p "$PROFILE" docker-env)"
  if ! docker version >/tmp/docker-version.out 2>/tmp/docker-version.err; then
    if grep -q "Maximum supported API version is" /tmp/docker-version.err; then
      max_api_version="$(sed -n 's/.*Maximum supported API version is \([0-9.]\+\).*/\1/p' /tmp/docker-version.err | head -n1)"
      if [[ -n "${max_api_version}" ]]; then
        docker_api_version="$max_api_version"
      fi
    fi
  fi

  if [[ -n "$docker_api_version" ]]; then
    if ! DOCKER_API_VERSION="$docker_api_version" docker images --format '{{.Repository}}:{{.Tag}}' | grep -Fxq "$AIRFLOW_IMAGE"; then
      echo "Missing image ${AIRFLOW_IMAGE} in Minikube Docker daemon (${PROFILE})."
      echo "Build images first: scripts/build_images.sh"
      exit 1
    fi
  elif ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -Fxq "$AIRFLOW_IMAGE"; then
    echo "Missing image ${AIRFLOW_IMAGE} in Minikube Docker daemon (${PROFILE})."
    echo "Build images first: scripts/build_images.sh"
    exit 1
  fi
}
