#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PLAYBOOK="${REPO_ROOT}/ops/newt_install/ansible/playbooks/deploy_monitoring_phase1.yml"
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc_vms.ini"
HOSTKEY_REFRESH_SCRIPT="${REPO_ROOT}/scripts/refresh_nuc_vm_hostkeys.sh"
SNAPSHOT_SCRIPT="${REPO_ROOT}/scripts/ansible_snapshot_edge_vms.sh"
ENV_FILE="${REPO_ROOT}/.env"

SNAPSHOT_NAME=""
SNAPSHOT_DESCRIPTION="Monitoring phase-1 baseline"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ansible_deploy_monitoring_phase1.sh [options] [ansible args...]

Options:
  --snapshot-name <name>         Snapshot monitoring VM after successful deploy
  --snapshot-description <text>  Snapshot description (default: Monitoring phase-1 baseline)
  -h, --help                     Show help

Environment:
  MONITORING_PULL_IMAGES=true    Pull latest container images before compose up
  GRAFANA_IMAGE=<image:tag>      Grafana image tag (default: grafana/grafana:11.1.0)
  TEMPO_IMAGE=<image:tag>        Tempo image tag (default: grafana/tempo:2.5.0)
  OTEL_COLLECTOR_IMAGE=<tag>     OTel collector image tag (default: otel/opentelemetry-collector:0.104.0)
  GRAFANA_ADMIN_USER             Grafana admin user (overrides op:// reference)
  GRAFANA_ADMIN_PASSWORD         Grafana admin password (overrides op:// reference)
EOF
}

EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --snapshot-name)
      SNAPSHOT_NAME=${2:-}
      shift 2
      ;;
    --snapshot-description)
      SNAPSHOT_DESCRIPTION=${2:-}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: required command not found: ansible-playbook" >&2
  exit 1
fi

if [[ "${SKIP_HOSTKEY_REFRESH:-0}" != "1" ]]; then
  "${HOSTKEY_REFRESH_SCRIPT}"
fi

PLAYBOOK_CMD=(ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}")
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  PLAYBOOK_CMD+=("${EXTRA_ARGS[@]}")
fi

USE_OP_RUN=0
if [[ -f "${ENV_FILE}" ]] && grep -q '^GRAFANA_ADMIN_' "${ENV_FILE}"; then
  if [[ -z "${GRAFANA_ADMIN_USER:-}" || -z "${GRAFANA_ADMIN_PASSWORD:-}" ]]; then
    USE_OP_RUN=1
  fi
fi

if [[ "${USE_OP_RUN}" == "1" ]]; then
  if ! command -v op >/dev/null 2>&1; then
    echo "Error: required command not found: op (needed for .env op:// refs)" >&2
    exit 1
  fi
  if ! op whoami >/dev/null 2>&1; then
    echo "1Password is not authenticated in this shell. Run: op signin" >&2
    exit 1
  fi
  if ! op run --env-file="${ENV_FILE}" -- "${PLAYBOOK_CMD[@]}"; then
    cat >&2 <<'EOF'
Monitoring deploy failed while running in 1Password env mode.
If this is an op outage or auth issue, temporary workaround:
  export GRAFANA_ADMIN_USER='<user>'
  export GRAFANA_ADMIN_PASSWORD='<password>'
  ./scripts/ansible_deploy_monitoring_phase1.sh
EOF
    exit 1
  fi
else
  "${PLAYBOOK_CMD[@]}"
fi

if [[ -n "${SNAPSHOT_NAME}" ]]; then
  "${SNAPSHOT_SCRIPT}" \
    --name "${SNAPSHOT_NAME}" \
    --targets monitoring \
    --description "${SNAPSHOT_DESCRIPTION}"
fi
