#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc.ini"

if ! command -v ansible >/dev/null 2>&1; then
  echo "Error: required command not found: ansible" >&2
  exit 1
fi

if [[ "${CONFIRM_NUKE_NUC_VMS:-}" != "YES" ]]; then
  cat >&2 <<'EOF'
Refusing teardown without explicit confirmation.
Re-run with: CONFIRM_NUKE_NUC_VMS=YES ./scripts/ansible_teardown_nuc_vms.sh
EOF
  exit 1
fi

ansible -i "${INVENTORY}" edge -b -m shell -a 'qm stop 9100 || true; qm stop 9200 || true'
ansible -i "${INVENTORY}" edge -b -m shell -a 'qm destroy 9100 --destroy-unreferenced-disks 1 --purge 1 || true'
ansible -i "${INVENTORY}" edge -b -m shell -a 'qm destroy 9200 --destroy-unreferenced-disks 1 --purge 1 || true'

echo "Teardown completed for VMIDs 9100 and 9200"

