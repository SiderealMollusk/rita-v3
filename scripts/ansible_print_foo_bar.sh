#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/print_foo_bar.yml"
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/localhost.ini"
ENV_FILE="${REPO_ROOT}/.env"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: required command not found: ansible-playbook" >&2
  exit 1
fi

if ! command -v op >/dev/null 2>&1; then
  echo "Error: required command not found: op" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  cat >&2 <<EOF
Missing .env file.
Create ${ENV_FILE} with op:// references first.
EOF
  exit 1
fi

if ! op whoami >/dev/null 2>&1; then
  echo "1Password is not authenticated in this shell. Run: op signin" >&2
  exit 1
fi

exec op run --no-masking --env-file="${ENV_FILE}" -- \
  ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}"
