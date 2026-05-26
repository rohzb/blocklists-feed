#!/usr/bin/env bash
# Sync then build feed artifacts via YALIC.
# Layout/output behavior is defined in config/feeds.yaml.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

YALIC_MODE="${YALIC_MODE:-docker}"
YALIC_IMAGE="${YALIC_IMAGE:-ghcr.io/rohzb/yalic:latest}"
YALIC_LOCAL_SOURCE="${YALIC_LOCAL_SOURCE:-0}"
CONFIG_REL="config/feeds.yaml"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

main() {
  if [[ "${YALIC_MODE}" == "docker" ]]; then
    require_cmd docker
    docker run --rm \
      -v "${REPO_ROOT}:/work" \
      -w /work \
      "${YALIC_IMAGE}" \
      sh -lc "yalic-pull -c \"/work/${CONFIG_REL}\" && yalic-build -c \"/work/${CONFIG_REL}\""
  elif [[ "${YALIC_MODE}" == "local" ]]; then
    (
      cd -- "${REPO_ROOT}"
      if [[ "${YALIC_LOCAL_SOURCE}" == "1" ]]; then
        PYTHONPATH="${REPO_ROOT}/../../packages/yalic/src${PYTHONPATH:+:${PYTHONPATH}}" \
          python -c "from yalic.cli.v03 import main_pull; raise SystemExit(main_pull(['-c','${CONFIG_REL}']))"
        PYTHONPATH="${REPO_ROOT}/../../packages/yalic/src${PYTHONPATH:+:${PYTHONPATH}}" \
          python -c "from yalic.cli.v03 import main_build; raise SystemExit(main_build(['-c','${CONFIG_REL}']))"
      else
        require_cmd yalic-pull
        require_cmd yalic-build
        yalic-pull -c "${CONFIG_REL}"
        yalic-build -c "${CONFIG_REL}"
      fi
    )
  else
    printf 'Invalid YALIC_MODE: %s (expected docker or local)\n' "${YALIC_MODE}" >&2
    exit 2
  fi
}

main "$@"
