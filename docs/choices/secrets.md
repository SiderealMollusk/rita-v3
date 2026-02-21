# Secrets Management Plan for Newt Installation

## Overview
We will store all sensitive values required for the Newt installation in **1Password** and retrieve them at runtime using the `op` CLI. No secret values are committed to the repository.

## What Secrets Are Needed?
| Secret Name | Purpose | 1Password Item | Notes |
|-------------|---------|----------------|-------|
| `newt_repo_key` | GPG public key for the Newt APT repository | `newt_secrets` (field `newt_repo_key`) | Used by the Ansible role to add the repo key.
| `op_service_token` | Service account token for non‑interactive `op` login | `newt_secrets` (field `op_service_token`) | Stored as a **Secret** type; injected into the dev‑container via an env file.
| `ssh_private_key` (optional) | SSH key for Ansible to connect to the NUC | `newt_secrets` (field `ssh_private_key`) | If you prefer key‑based auth instead of password.

## Retrieval Workflow
1. **Login to 1Password** (once per session)
   ```bash
   op signin --account <your‑team> --raw > ~/.op-token
   export OP_SESSION_myteam=$(cat ~/.op-token)
   ```
   In the dev‑container this can be done automatically via a `.env` file.
2. **Fetch a secret** in an Ansible task:
   ```yaml
   - name: Get Newt GPG key from 1Password
     command: op item get newt_secrets --fields newt_repo_key --format json
     register: newt_key_json
     changed_when: false
   - set_fact:
       newt_repo_key: "{{ newt_key_json.stdout | from_json | json_query('value') }}"
   ```
3. **Pass the secret** to the role via `vars_files` or directly as a fact. The `vars/secrets.yml` file is **generated at runtime** and never checked into VCS.

## Dev Container Integration
- Create a file `devcontainer/devcontainer.env` (listed in `.gitignore`) containing:
  ```
  OP_SERVICE_ACCOUNT_TOKEN=YOUR_SERVICE_TOKEN
  ```
- The Dockerfile copies the `op` binary and sets `ENV OP_SESSION_myteam=${OP_SERVICE_ACCOUNT_TOKEN}` so the container can call `op` without interactive login.

## Security Best Practices
- **Never** store raw secret values in the repository.
- Keep the `devcontainer.env` file out of version control (`.gitignore`).
- Rotate the service token periodically via the 1Password admin console.
- Restrict the 1Password item permissions to only the users who need to run the playbooks.

## Roll‑back of Secrets
If a secret is compromised, simply:
1. Delete or rotate the field in the 1Password item.
2. Re‑run the playbook; the new secret will be fetched automatically.

---
*This document lives in `docs/choices/secrets.md` and should be referenced by the Ansible role README and any onboarding guides.*
