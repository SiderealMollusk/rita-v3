#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/clone_edge_vms.yml"
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc.ini"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: required command not found: ansible-playbook" >&2
  exit 1
fi

if [[ -z "${PVE_VM_SSH_PUBLIC_KEY:-}" ]]; then
  if [[ -f "${HOME}/.ssh/id_ed25519.pub" ]]; then
    export PVE_VM_SSH_PUBLIC_KEY
    PVE_VM_SSH_PUBLIC_KEY=$(cat "${HOME}/.ssh/id_ed25519.pub")
  elif [[ -f "${HOME}/.ssh/id_rsa.pub" ]]; then
    export PVE_VM_SSH_PUBLIC_KEY
    PVE_VM_SSH_PUBLIC_KEY=$(cat "${HOME}/.ssh/id_rsa.pub")
  fi
fi

exec ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" "$@"

