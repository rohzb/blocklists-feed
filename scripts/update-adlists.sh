#!/usr/bin/env bash
# Simple adlist updater: fetch CUII and write per-source and combined
# hosts files into ./adlists.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OUT_DIR="${REPO_ROOT}/adlists"
TMP_DIR="$(mktemp -d)"

cleanup() {
  [[ -d "${TMP_DIR}" ]] && rm -rf -- "${TMP_DIR}"
}
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

# Keep only reasonable domain-like entries to avoid bad lines polluting output.
normalize_domains() {
  awk '
    {
      line = tolower($0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      if (line ~ /^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/) print line
    }
  '
}

domains_to_hosts() {
  awk '{print "0.0.0.0 " $1}'
}

main() {
  require_cmd curl
  require_cmd jq
  require_cmd awk
  require_cmd sort

  mkdir -p -- "${OUT_DIR}"

  curl -fsSL 'https://api.cuiiliste.de/blocked_domains' \
    | jq -r '.[].domain' \
    | normalize_domains \
    | sort -u >"${TMP_DIR}/cuii.domains"

  cat "${TMP_DIR}/cuii.domains" | domains_to_hosts >"${OUT_DIR}/cuii.hosts"

  cat "${TMP_DIR}/cuii.domains" \
    | sort -u \
    | domains_to_hosts >"${OUT_DIR}/combined.hosts"

  printf 'Updated: %s\n' "${OUT_DIR}/cuii.hosts"
  printf 'Updated: %s\n' "${OUT_DIR}/combined.hosts"
}

main "$@"
