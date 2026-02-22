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

## 2026-02-22: NUC VM Network Baseline Debug + Hardening

### Summary
- Completed root-cause analysis of repeated VM DNS/apt failures during post-clone baseline prep.
- Confirmed failures were caused by incorrect network assumptions (`/24` + `192.168.5.1`) versus actual LAN (`/22` with gateway `192.168.4.1`).
- Hardened Ansible automation to use inventory-backed network defaults and removed brittle host-route auto-detection.

### Detailed Findings
- Proxmox host network:
  - `vmbr0`: `192.168.5.173/22`
  - default gateway: `192.168.4.1`
- VM `newt` had previously been configured as `192.168.5.181/24` with gateway `192.168.5.1`, causing unreachable gateway and DNS hangs.
- After correcting to `192.168.5.181/22` + `192.168.4.1`, DNS and apt behavior normalized.

### Automation Changes
- Added shared inventory vars in `ops/newt_install/ansible/inventory/group_vars/all.yml`:
  - `nuc_vm_gateway`
  - `nuc_vm_dns`
  - `nuc_vm_definitions` (newt/monitoring VMID, IP CIDR, CPU, RAM)
- Updated clone and converge playbooks to consume inventory vars by default, with env overrides remaining optional.
- Added/used `scripts/refresh_nuc_vm_hostkeys.sh` to make host key rotation after re-clone routine.
- Added one-shot `newt` baseline converge path (`converge_newt_baseline`) that:
  - applies cloud-init network,
  - reboots and waits,
  - validates DNS/HTTPS,
  - installs/enables `qemu-guest-agent`,
  - snapshots if baseline snapshot does not already exist.

### Verification Outcome
- `newt` baseline now validates successfully:
  - SSH reachable
  - IP/route correct (`192.168.5.181/22`, gw `192.168.4.1`)
  - DNS resolution works
  - HTTPS outbound works
  - `sudo apt-get update` works
  - `qemu-guest-agent` install/start completed in automation
- Baseline snapshot (`baseline-clean`) created for VMID `9100`.

### Next
- Converge and validate `monitoring` baseline with the same network model.
- Begin Newt app-layer deployment playbook on `newt`.
