# Developer Log

## 2026-02-20: Secrets + Proxmox VM Provisioning Automation

### Completed
- Standardized secrets workflow to 1Password runtime resolution:
  - `.env` contains `op://` references.
  - scripts use `op run --env-file=.env -- ...`.
- Added/updated local Ansible demo flow for `foo/bar` secret retrieval.
- Added NUC Proxmox host inventory and playbooks for:
  - switching enterprise repos to no-subscription repos,
  - baseline host prep.
- Added Proxmox VM automation:
  - build Debian cloud-init template,
  - clone `newt` + `monitoring` VMs with fixed IPs,
  - guest prep playbook for `qemu-guest-agent`.
- Added snapshot automation playbook + wrapper with phase-oriented arguments.

### Notable Fixes During Bring-Up
- Proxmox 9 repo handling updated to disable enterprise sources across `.list` and `.sources` files.
- Template build made idempotent:
  - removed interactive `qm set --cipassword` hang,
  - guarded cloud-init disk creation (`ide2`) to avoid duplicate LV errors.
- Docker package install made distro-tolerant with Compose fallback logic.

### Current State
- Proxmox template (`9000`) exists and is usable.
- `newt` (`9100`) and `monitoring` (`9200`) VMs are cloned/running with fixed IP assignments.
- Documentation now covers run order, assumptions, and snapshot workflow.

## 2026-02-21: Standardized NUC VM Bring-Up Flow

### Changes
- Split VM flow into explicit stages:
  - clone/configure cloud-init,
  - validate network/DNS,
  - install guest-agent.
- Added rebuild-safe teardown script for VMIDs `9100` and `9200` with explicit confirmation guard.
- Removed DNS/source mutation from guest-agent prep playbook to keep role separation clean.

### Result
- Workflow now matches standard image + cloud-init practice:
  - network baseline handled at clone-time,
  - preflight validates before apt-based tasks,
  - prep playbook focuses only on guest package/service state.
- Network defaults are now inventory-backed in `inventory/group_vars/nuc_vms.yml` with env overrides optional.
