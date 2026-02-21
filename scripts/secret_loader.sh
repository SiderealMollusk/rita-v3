#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

# Load local env overrides if present (git-ignored).
if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/.env"
fi

: "${OP_VAULT:=rita-v3}"

require_command() {
  local cmd=$1
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: required command not found: ${cmd}" >&2
    exit 1
  fi
}

has_op_auth() {
  # Validate actual CLI auth state. A non-empty OP_SERVICE_ACCOUNT_TOKEN
  # alone is not sufficient if the token is stale/invalid.
  op whoami >/dev/null 2>&1
}

ensure_op_auth() {
  require_command op

  if has_op_auth; then
    return 0
  fi

  cat >&2 <<'EOF'
1Password is not authenticated for this shell.
Run `op signin` in your own terminal, or set OP_SERVICE_ACCOUNT_TOKEN in .env.
EOF
  exit 1
}
