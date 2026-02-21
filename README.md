# rita-v3

## 1Password + Ansible (minimal flow)

This repo uses 1Password secret references in local `.env` and resolves them at runtime with `op run`.

### 1. Create `.env` (git-ignored)

```dotenv
OP_VAULT=wsrkpssm6j5cq63t5kni7cfkbm
FOO=op://wsrkpssm6j5cq63t5kni7cfkbm/foo/bar
```

Notes:
- Keep only references (`op://...`) in `.env`, not raw secrets.
- Do not store session tokens in `.env`.

### 2. Sign in from your system shell

```bash
op signin
op whoami
```

Use the same shell session for project commands.

### 3. Run the demo playbook

```bash
./scripts/ansible_print_foo_bar.sh
```

What this script does:
- Runs `ansible-playbook` through `op run --no-masking --env-file=.env`.
- `op run` resolves `FOO` before Ansible starts.
- Playbook prints `Value of foo: bar` for milestone demo purposes.

Security note:
- `--no-masking` intentionally allows secrets to appear in terminal output. Use only for local debugging/demo.

## Files

- Script: `scripts/ansible_print_foo_bar.sh`
- Playbook: `ops/newt_install/ansible/playbooks/print_foo_bar.yml`
- Inventory: `ops/newt_install/ansible/inventory/localhost.ini`
