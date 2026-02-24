## VPS Notes

Provider: netcup

## Current Issue (2026-02-23)

### Summary
- DNS is correct (`*.virgil.info` and root `virgil.info` both point to `159.195.41.160`).
- Newt site is connected and online.
- Pangolin resources are created, but Traefik dynamic config shows resource routers only on `web` (HTTP), not `websecure` (HTTPS).
- Result:
  - `http://<resource>.virgil.info` works (302/auth flow).
  - `https://<resource>.virgil.info` returns Traefik default cert + `404`.

### Evidence
- `docker exec traefik wget -qO- http://pangolin:3001/api/v1/traefik-config | jq .`
  showed routers with `entryPoints: ["web"]` only.
- No router entries observed on `websecure`/TLS for affected hosts.

## Terse Solution Possibilities

1. Pangolin-side fix (preferred)
- Recreate one HTTPS resource from scratch.
- Save `Targets`, `Proxy`, and `General` settings.
- Re-check `traefik-config` for `entryPoints` including `websecure` and a `tls` block.

2. Service restart to clear stale config state
- Restart `pangolin` and `traefik`.
- Re-check `traefik-config` immediately after recreate.

3. Temporary workaround
- Use HTTP resource path for lab progress.
- Track HTTPS as separate platform bug/config issue.

4. Manual Traefik override (last resort)
- Add a file-provider router on `websecure` for specific hostname(s).
- Use only if Pangolin UI/config generation cannot be fixed quickly.

## Implications for SSH Publishing

1. SSH over Raw TCP/UDP resource may still work
- Raw TCP resources do not depend on the HTTPS web router path.
- You can likely expose SSH even while HTTPS resource routing is broken.

2. Browser-access/SSO UX will be degraded
- Any workflows relying on Pangolin HTTPS web resources/auth pages can be impacted.
- Plan for direct TCP endpoint usage for SSH first.

3. Risk posture
- Do not publish high-privilege admin targets publicly until HTTPS routing/cert path is clean.
- Start with low-risk targets and explicit access controls.

## Quick Recovery/Backup Notes

- netcup VPS has no native snapshot in this setup.
- Current pragmatic backup option:
  - export compose + config + critical data to local Mac periodically,
  - optionally image disk externally if needed.
