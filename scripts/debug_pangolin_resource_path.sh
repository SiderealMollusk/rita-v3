#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOSTKEY_REFRESH_SCRIPT="${REPO_ROOT}/scripts/refresh_nuc_vm_hostkeys.sh"

# Defaults can be overridden via env vars.
RESOURCE_DOMAIN="${RESOURCE_DOMAIN:-h4.virgil.info}"
PANGOLIN_ENDPOINT="${PANGOLIN_ENDPOINT:-pangolin.virgil.info}"
VPS_SSH_HOST="${VPS_SSH_HOST:-root@100.115.240.47}"
NEWT_SSH_HOST="${NEWT_SSH_HOST:-debian@192.168.5.181}"
BACKEND_HOST="${BACKEND_HOST:-192.168.5.181}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
NEWT_CONTAINER_NAME="${NEWT_CONTAINER_NAME:-newt}"
HELLO_CONTAINER_NAME="${HELLO_CONTAINER_NAME:-newt-hello}"

if [[ "${SKIP_HOSTKEY_REFRESH:-0}" != "1" ]]; then
  "${HOSTKEY_REFRESH_SCRIPT}" >/dev/null 2>&1 || true
fi

for cmd in ssh curl dig; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done

SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout=8
  -o StrictHostKeyChecking=accept-new
)

section() {
  printf '\n== %s ==\n' "$1"
}

run_local() {
  local label="$1"
  shift
  echo "-- ${label}"
  "$@"
  local rc=$?
  if [[ "$rc" -eq 0 ]]; then
    return 0
  fi
  echo "[fail] rc=${rc}"
  return "$rc"
}

run_ssh() {
  local host="$1"
  local label="$2"
  local script="$3"
  echo "-- ${label} (${host})"
  ssh "${SSH_OPTS[@]}" "$host" "$script"
  local rc=$?
  if [[ "$rc" -eq 0 ]]; then
    return 0
  fi
  echo "[fail] rc=${rc}"
  return "$rc"
}

section "Input"
printf 'RESOURCE_DOMAIN=%s\n' "$RESOURCE_DOMAIN"
printf 'PANGOLIN_ENDPOINT=%s\n' "$PANGOLIN_ENDPOINT"
printf 'VPS_SSH_HOST=%s\n' "$VPS_SSH_HOST"
printf 'NEWT_SSH_HOST=%s\n' "$NEWT_SSH_HOST"
printf 'BACKEND=%s:%s\n' "$BACKEND_HOST" "$BACKEND_PORT"

section "Public DNS + Edge Response"
run_local "dig A ${RESOURCE_DOMAIN}" dig +short A "$RESOURCE_DOMAIN" || true
run_local "dig AAAA ${RESOURCE_DOMAIN}" dig +short AAAA "$RESOURCE_DOMAIN" || true
run_local "curl HTTP HEAD" curl -sSI --max-time 12 "http://${RESOURCE_DOMAIN}" | sed -n '1,12p' || true
run_local "curl HTTPS HEAD (insecure)" curl -skSI --max-time 12 "https://${RESOURCE_DOMAIN}" | sed -n '1,16p' || true

section "Newt VM Health"
run_ssh "$NEWT_SSH_HOST" "docker ps (newt/hello)" "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | egrep '${NEWT_CONTAINER_NAME}|${HELLO_CONTAINER_NAME}|NAMES'" || true
run_ssh "$NEWT_SSH_HOST" "backend local HTTP" "curl -sSI --max-time 8 http://127.0.0.1:${BACKEND_PORT} | sed -n '1,8p'" || true
run_ssh "$NEWT_SSH_HOST" "newt logs tail" "docker logs --tail=40 ${NEWT_CONTAINER_NAME} 2>&1 | egrep -i 'Websocket connected|Tunnel connection|Started tcp proxy|Failed to connect|Failed to get token|ERROR|WARN' || true" || true

section "VPS Pangolin/Traefik"
run_ssh "$VPS_SSH_HOST" "docker ps (pangolin stack)" "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | egrep 'pangolin|traefik|gerbil|NAMES'" || true

# Show router/service entries for the requested resource hostname.
run_ssh "$VPS_SSH_HOST" "traefik-config route/service entries" "docker exec traefik wget -qO- http://pangolin:3001/api/v1/traefik-config | jq -r --arg d '${RESOURCE_DOMAIN}' '
  [
    ("ROUTERS"),
    (.http.routers | to_entries[]
      | select((.value.rule // "") | test(\$d))
      | ["-", .key, ((.value.entryPoints // [])|join(",")), (if .value.tls then "tls" else "no-tls" end), (.value.rule // "")] | @tsv),
    ("SERVICES"),
    (.http.services | to_entries[]
      | select((.value.loadBalancer.servers // []) | tostring | test("${BACKEND_HOST}"))
      | ["-", .key, ((.value.loadBalancer.servers // []) | map(.url) | join(","))] | @tsv)
  ] | .[]
'" || true

run_ssh "$VPS_SSH_HOST" "vps -> backend HTTP probe" "curl -sSI --max-time 8 http://${BACKEND_HOST}:${BACKEND_PORT} | sed -n '1,8p'" || true

section "Quick Reading"
cat <<'TXT'
- If HTTPS returns 404 with TRAEFIK DEFAULT CERT: router/tls generation issue at VPS.
- If VPS -> backend probe times out: tunnel path/site endpoint issue, not DNS.
- If Newt logs show websocket+tunnel+tcp proxy and backend local is 200, Newt side is healthy.
TXT
