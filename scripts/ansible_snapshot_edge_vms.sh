#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/snapshot_edge_vms.yml"
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc.ini"

SNAPSHOT_NAME=""
SNAPSHOT_TARGETS="newt,monitoring"
EXPECTED_PARENT=""
SNAPSHOT_DESCRIPTION=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ansible_snapshot_edge_vms.sh --name <snapshot_name> [options]

Options:
  --name <name>                 Snapshot name to create (required)
  --targets <csv>               Targets: newt,monitoring (default: newt,monitoring)
  --expected-parent <name>      Require this parent snapshot to exist before create
  --description <text>          Snapshot description
  -h, --help                    Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      SNAPSHOT_NAME=${2:-}
      shift 2
      ;;
    --targets)
      SNAPSHOT_TARGETS=${2:-}
      shift 2
      ;;
    --expected-parent)
      EXPECTED_PARENT=${2:-}
      shift 2
      ;;
    --description)
      SNAPSHOT_DESCRIPTION=${2:-}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: required command not found: ansible-playbook" >&2
  exit 1
fi

if [[ -z "${SNAPSHOT_NAME}" ]]; then
  echo "Error: --name is required" >&2
  usage
  exit 1
fi

IFS=',' read -r -a TARGET_ARRAY <<<"${SNAPSHOT_TARGETS}"

exec ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" \
  -e "snapshot_name=${SNAPSHOT_NAME}" \
  -e "snapshot_description=${SNAPSHOT_DESCRIPTION}" \
  -e "expected_parent_snapshot=${EXPECTED_PARENT}" \
  -e "snapshot_targets_csv=${SNAPSHOT_TARGETS}" \
  "$@"
