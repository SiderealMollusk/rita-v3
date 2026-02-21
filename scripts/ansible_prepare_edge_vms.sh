#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/prepare_edge_vms.yml"
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/edge_vms.ini"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: required command not found: ansible-playbook" >&2
  exit 1
fi

exec ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" "$@"

