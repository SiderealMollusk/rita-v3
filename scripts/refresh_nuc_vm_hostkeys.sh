#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
INVENTORY="${REPO_ROOT}/ops/newt_install/ansible/inventory/nuc_vms.ini"

if ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "Error: required command not found: ssh-keygen" >&2
  exit 1
fi

if ! command -v ssh-keyscan >/dev/null 2>&1; then
  echo "Error: required command not found: ssh-keyscan" >&2
  exit 1
fi

if [[ ! -f "${INVENTORY}" ]]; then
  echo "Error: inventory not found: ${INVENTORY}" >&2
  exit 1
fi

HOSTS=()
while IFS= read -r host; do
  [[ -n "${host}" ]] || continue
  HOSTS+=("${host}")
done < <(sed -nE 's/.*ansible_host=([^ ]+).*/\1/p' "${INVENTORY}" | sort -u)

if [[ ${#HOSTS[@]} -eq 0 ]]; then
  echo "Error: no ansible_host entries found in ${INVENTORY}" >&2
  exit 1
fi

for host in "${HOSTS[@]}"; do
  ssh-keygen -R "${host}" >/dev/null 2>&1 || true
  ssh-keygen -R "[${host}]:22" >/dev/null 2>&1 || true
done

for host in "${HOSTS[@]}"; do
  ssh-keyscan -H "${host}" >>"${HOME}/.ssh/known_hosts"
done

echo "Refreshed SSH host keys for: ${HOSTS[*]}"
