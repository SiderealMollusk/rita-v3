#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/deploy_newt_on_vm.yml"
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc_vms.ini"
ENV_FILE="${REPO_ROOT}/.env"
HOSTKEY_REFRESH_SCRIPT="${REPO_ROOT}/scripts/refresh_nuc_vm_hostkeys.sh"

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
Create ${ENV_FILE} with NEWT_ENDPOINT/NEWT_ID/NEWT_SECRET op:// references first.
EOF
  exit 1
fi

if ! op whoami >/dev/null 2>&1; then
  echo "1Password is not authenticated in this shell. Run: op signin" >&2
  exit 1
fi

if [[ "${SKIP_HOSTKEY_REFRESH:-0}" != "1" ]]; then
  "${HOSTKEY_REFRESH_SCRIPT}"
fi

exec op run --env-file="${ENV_FILE}" -- \
  ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" "$@"
