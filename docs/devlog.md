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
