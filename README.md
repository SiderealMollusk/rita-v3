# rita-v3

## 1Password + Ansible (minimal flow)

This repo uses 1Password secret references in local `.env` and resolves them at runtime with `op run`.

### 1. Create `.env` (git-ignored)

Start from the committed template:

```bash
cp .env.example .env
```

```dotenv
OP_VAULT=wsrkpssm6j5cq63t5kni7cfkbm
FOO=op://wsrkpssm6j5cq63t5kni7cfkbm/foo/bar
```

Notes:
- Keep only references (`op://...`) in `.env`, not raw secrets.
- Do not store session tokens in `.env`.
- Keep non-secrets (for example `GRAFANA_IMAGE`, `MONITORING_PULL_IMAGES`) in `.env.example` and `.env`.

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

## NUC Proxmox Prep

Prerequisite: this playbook assumes SSH key auth for `root@192.168.5.173`.

Bootstrap once from your Mac:

```bash
ssh-copy-id root@192.168.5.173
ssh root@192.168.5.173
```

If you have not installed key auth yet, use password prompt mode:

```bash
./scripts/ansible_prepare_nuc_newt.sh --ask-pass
```

To prepare `root@192.168.5.173` (inventory alias `nuc`) for Pangolin/Newt:

```bash
./scripts/ansible_fix_nuc_repos.sh
./scripts/ansible_prepare_nuc_newt.sh
```

If apt fails with Proxmox enterprise `401 Unauthorized`, run the repo-fix command first.

Related files:
- Script: `scripts/ansible_fix_nuc_repos.sh`
- Playbook: `ops/newt_install/ansible/playbooks/fix_proxmox_repos.yml`
- Script: `scripts/ansible_prepare_nuc_newt.sh`
- Playbook: `ops/newt_install/ansible/playbooks/prepare_nuc_for_newt.yml`
- Inventory: `ops/newt_install/ansible/inventory/nuc.ini`

## NUC VM Provisioning (Template + Clones)

This creates one Debian cloud-init template on Proxmox and clones two VMs:
- `newt` (VMID `9100`, IP `192.168.5.181/24`)
- `monitoring` (VMID `9200`, IP `192.168.5.182/24`)

Cloud-init defaults set by clone playbook:
- user: `debian`
- network values from `ops/newt_install/ansible/inventory/group_vars/nuc_vms.yml`

Run in order:

```bash
./scripts/ansible_fix_nuc_repos.sh
./scripts/ansible_build_nuc_debian_template.sh
./scripts/ansible_clone_nuc_edge_vms.sh
./scripts/ansible_validate_nuc_vms_network.sh
./scripts/ansible_prepare_nuc_vms.sh
```

Teardown/rebuild helper:

```bash
CONFIRM_NUKE_NUC_VMS=YES ./scripts/ansible_teardown_nuc_vms.sh
```

Related files:
- Script: `scripts/ansible_build_nuc_debian_template.sh`
- Playbook: `ops/newt_install/ansible/playbooks/build_debian_template.yml`
- Script: `scripts/ansible_clone_nuc_edge_vms.sh`
- Playbook: `ops/newt_install/ansible/playbooks/clone_edge_vms.yml`
- Script: `scripts/ansible_validate_nuc_vms_network.sh`
- Playbook: `ops/newt_install/ansible/playbooks/validate_nuc_vms_network.yml`
- Script: `scripts/ansible_prepare_nuc_vms.sh`
- Playbook: `ops/newt_install/ansible/playbooks/prepare_nuc_vms.yml`
- Script: `scripts/ansible_converge_newt_baseline.sh`
- Playbook: `ops/newt_install/ansible/playbooks/converge_newt_baseline.yml`
- Script: `scripts/ansible_teardown_nuc_vms.sh`
- Script: `scripts/refresh_nuc_vm_hostkeys.sh` (auto-called by `ansible_prepare_nuc_vms.sh`)
- Script: `scripts/ansible_snapshot_edge_vms.sh`
- Playbook: `ops/newt_install/ansible/playbooks/snapshot_edge_vms.yml`
- VM inventory scaffold: `ops/newt_install/ansible/inventory/nuc_vms.ini`

## Snapshot Workflow

`converge_newt_baseline` uses inventory `group_vars` by default. Optional runtime override:

```bash
NUC_VM_GATEWAY=192.168.5.1 NUC_VM_DNS=192.168.5.1 ./scripts/ansible_converge_newt_baseline.sh
```

Create baseline snapshots after VM clone and guest prep:

```bash
./scripts/ansible_snapshot_edge_vms.sh --name baseline-clean --description "Post-clone baseline"
```

Create a phase snapshot for a single VM:

```bash
./scripts/ansible_snapshot_edge_vms.sh --name post-newt-bootstrap --targets newt
```

Require expected parent phase before new snapshot:

```bash
./scripts/ansible_snapshot_edge_vms.sh --name phase-2 --expected-parent baseline-clean
```

## Deploy Newt on VM

Add these `op://` references to `.env`:

```dotenv
NEWT_ENDPOINT=op://<vault>/<item>/endpoint
NEWT_ID=op://<vault>/<item>/id
NEWT_SECRET=op://<vault>/<item>/secret
```

Optional overrides:

```dotenv
NEWT_IMAGE=fosrl/newt:latest
NEWT_NETWORK_MODE=host
NEWT_MOUNT_DOCKER_SOCKET=false
```

Run deploy:

```bash
./scripts/ansible_deploy_newt_vm.sh
```

What it does:
- resolves `NEWT_*` via `op run --env-file=.env`,
- writes `/opt/newt/newt-config.secret` on VM (`0600`),
- writes `/opt/newt/docker-compose.yml`,
- runs compose `pull` + `up -d`,
- verifies container `newt` is running.

Related files:
- Script: `scripts/ansible_deploy_newt_vm.sh`
- Playbook: `ops/newt_install/ansible/playbooks/deploy_newt_on_vm.yml`

## Deploy Minimal Test Web Page (newt VM)

Deploy a dead-simple HTTP test page on `newt` (default port `8080`):

```bash
./scripts/ansible_deploy_newt_hello_page.sh
```

Optional port override:

```bash
NEWT_HELLO_PORT=18080 ./scripts/ansible_deploy_newt_hello_page.sh
```

This is meant as the first Pangolin public-resource validation target.

Related files:
- Script: `scripts/ansible_deploy_newt_hello_page.sh`
- Playbook: `ops/newt_install/ansible/playbooks/deploy_newt_hello_page.yml`
