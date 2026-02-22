#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/converge_newt_baseline.yml"
PVE_INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc.ini"
VM_INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc_vms.ini"
HOSTKEY_REFRESH_SCRIPT="${REPO_ROOT}/scripts/refresh_nuc_vm_hostkeys.sh"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: required command not found: ansible-playbook" >&2
  exit 1
fi

if [[ "${SKIP_HOSTKEY_REFRESH:-0}" != "1" ]]; then
  "${HOSTKEY_REFRESH_SCRIPT}"
fi

exec ansible-playbook -i "${PVE_INVENTORY}" -i "${VM_INVENTORY}" "${PLAYBOOK}" "$@"

