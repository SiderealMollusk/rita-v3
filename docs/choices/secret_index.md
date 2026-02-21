# Secret Index

| Env Variable | Vault Key (1Password Item / Field) | Last Updated | Rotation Method / Implications |
|--------------|-----------------------------------|--------------|--------------------------------|
| `NEWT_REPO_KEY` | `newt_secrets` / `newt_repo_key` | 2026‑02‑20 | Rotate by regenerating the GPG key in the repo and updating the 1Password field; requires re‑run of Ansible to refresh repo key.
| `OP_SERVICE_ACCOUNT_TOKEN` | `newt_secrets` / `op_service_token` | 2026‑02‑20 | Rotate via 1Password UI; revoke old token and generate a new service token, then re‑login (`op signin`) before next playbook run.
| `SSH_PRIVATE_KEY` (optional) | `newt_secrets` / `ssh_private_key` | 2026‑02‑20 | Rotate by generating a new SSH key pair, updating the 1Password field, and distributing the new public key to the NUC's `authorized_keys`.

*All secrets are stored exclusively in 1Password and accessed at runtime with the `op` CLI. No secret values are committed to the repository.*
