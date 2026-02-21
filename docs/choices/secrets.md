# Secrets Runbook

## Principle
- 1Password CLI (`op`) is the only secret interface used by project scripts.
- Scripts must never prompt for credentials or store session tokens in repo files.
- Agents can run scripts safely because scripts fail fast unless `op` is already authenticated.

## Inputs
- Default vault: `rita-v3` (override with `OP_VAULT`).
- Secret inventory: [Secret Index](./secret_index.md).
- Optional automation auth: `OP_SERVICE_ACCOUNT_TOKEN` in local `.env` (git-ignored).

## Operator Flow
1. Authenticate once in your own terminal:
   ```bash
   op signin
   ```
2. Verify session:
   ```bash
   op whoami
   ```
3. Run project scripts/playbooks; they call `op` directly and fail with a clear message if auth is missing.

## Milestone 1 (Ansible Demo)
This milestone fetches item `foo`, field `bar`, and prints it:

```bash
./scripts/ansible_print_foo_bar.sh
```

Overrides:

```bash
OP_VAULT=rita-v3 OP_ITEM=foo OP_FIELD=bar ./scripts/ansible_print_foo_bar.sh
```

## Security Notes
- Never commit secret values.
- Prefer `no_log: true` in Ansible for real tasks.
- Only print secrets in explicit test/demo tasks like Milestone 1.
