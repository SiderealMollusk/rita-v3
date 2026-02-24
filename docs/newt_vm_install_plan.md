# Newt on NUC VM: Install Plan

Date: 2026-02-22
Scope: Install and operate `newt` on VM `9100` (`newt`) in a reproducible way from this ops repo.

## Goal

Stand up `newt` on the `newt` VM with:
- repeatable deploy/upgrade flow,
- secrets sourced from 1Password,
- clear verification gates before proceeding to app/resource exposure.

## Happy Path

1. Preconditions
- Proxmox + VM lifecycle is healthy (`9000` template, `9100` clone, network validated).
- `newt` VM has Docker and `qemu-guest-agent` installed (already covered by existing scripts).
- Pangolin server is reachable from VM over HTTPS.

2. Create site credentials in Pangolin
- In Pangolin UI, create a Newt site.
- Capture:
  - `endpoint` (e.g. `https://pangolin.example.com`)
  - `id` (not secret)
  - `secret` (secret)

3. Store credentials in 1Password
- Create/update one item for this VM site, for example:
  - `endpoint`
  - `id`
  - `secret`
- Keep using `op://...` references in local `.env`, not raw secrets in git.

4. Deploy Newt on VM (Docker Compose path)
- Create a VM-local config secret file (JSON) from 1Password-backed values.
- Run `fosrl/newt` with:
  - `CONFIG_FILE=/run/secrets/newt-config` (preferred)
  - restart policy `unless-stopped`
- Start with `docker compose up -d`.

5. Verify connector health
- On VM:
  - `docker compose ps`
  - `docker compose logs --tail=200 newt`
- In Pangolin UI:
  - site shows connected/healthy.

6. Freeze known-good state
- Snapshot VM `9100` after successful Newt connect + stable logs.

## Gotchas / Foot-Guns

1. Wrong VM network model
- Your LAN is `/22` with gateway `192.168.4.1`.
- Using `/24` + `192.168.5.1` causes DNS and apt hangs.

2. New clones need boot time
- Immediate SSH after clone can fail with `connection refused`.
- Add explicit wait/retry before validation/prep.

3. Host key churn after rebuilds
- Re-cloning rotates SSH host keys; stale `known_hosts` causes Ansible SSH failures.
- Keep hostkey refresh in the wrapper flow.

4. Secret leakage
- Avoid plain `NEWT_SECRET` in committed compose files.
- Prefer compose secret + `CONFIG_FILE`.

5. Docker socket exposure
- `DOCKER_SOCKET` enables blueprint/label discovery but expands blast radius.
- Only mount `/var/run/docker.sock` if needed.

6. VPS-side tunnel ports
- Pangolin/Gerbil side must expose required ports, especially UDP `51820` for site tunnels.

7. Drift from `latest`
- Pin image versions after first stable deploy to avoid surprise behavior changes.

## Ansible Adaptation (Recommended Repo Direction)

1. Add a dedicated playbook for Newt app-layer deploy
- Suggested: `ops/newt_install/ansible/playbooks/deploy_newt_on_vm.yml`
- Target group: `newt_nodes`.

2. Playbook responsibilities
- Preflight:
  - verify Docker/Compose available,
  - verify Pangolin endpoint resolves and is reachable (`curl -I`).
- Render config JSON from env vars injected by `op run`:
  - destination `/opt/newt/newt-config.secret` mode `0600`.
- Render compose file in `/opt/newt/docker-compose.yml`.
- Run:
  - `docker compose pull`
  - `docker compose up -d`
- Verify:
  - container running,
  - logs do not contain auth/connect retry storms.

3. Wrapper script
- Suggested: `scripts/ansible_deploy_newt_vm.sh`
- Behavior:
  - uses `op run --env-file=.env -- ansible-playbook ...`,
  - does not require remote `op` CLI on VM.

4. Secrets contract
- Keep only references in `.env`:
  - `NEWT_ENDPOINT=op://...`
  - `NEWT_ID=op://...`
  - `NEWT_SECRET=op://...`
- Ansible reads resolved env vars (`lookup('env', ...)`) with `no_log: true` on secret tasks.

5. Idempotent upgrade path
- Add companion playbook for updates:
  - optional image tag variable,
  - `pull + up -d` + health check.

## Definition of Done

- `newt` container is running on VM `9100`.
- Pangolin site status is connected.
- Re-run of deploy playbook is idempotent (`changed=0` or expected minimal changes).
- `baseline-clean` snapshot exists after successful converge.

## Primary Sources

- Install Sites (Newt binary/docker/compose): https://docs.pangolin.net/manage/sites/install-site
- Configure Sites (flags/env vars for Newt): https://docs.pangolin.net/manage/sites/configure-site
- Site Credentials: https://docs.pangolin.net/manage/sites/credentials
- Update Sites: https://docs.pangolin.net/manage/sites/update-site
- DNS & Networking (Pangolin/Gerbil ports): https://docs.pangolin.net/self-host/dns-and-networking
- Newt repository: https://github.com/fosrl/newt
