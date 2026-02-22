# NUC
proxmox VE
pve.nuc.homelab
16GB RAM, 256GB SSD
https://192.168.5.173:8006/#v1:0:=node%2Fpve:4

Logs:
- just installed proxmox VE 9.1.1
- I want to install newt.

## Ansible Bootstrap (Pangolin/Newt prep)

Connection assumption: Ansible uses SSH key auth for `root@192.168.5.173`.

Bootstrap key auth first:

```bash
ssh-copy-id root@192.168.5.173
ssh root@192.168.5.173
```

If key auth is not installed yet, run with password prompt:

```bash
./scripts/ansible_prepare_nuc_newt.sh --ask-pass
```

Inventory group: `edge`, host alias: `nuc`

```ini
[edge]
nuc ansible_host=192.168.5.173 ansible_user=root ansible_port=22
```

Run baseline prep:

```bash
./scripts/ansible_fix_nuc_repos.sh
./scripts/ansible_prepare_nuc_newt.sh
```

Use `--ask-pass` on either command if you are not on SSH key auth yet.

What it configures:
- apt cache refresh and base packages
- Docker engine + Compose plugin
- Docker enabled and started
- IPv4 forwarding (`/etc/sysctl.d/99-pangolin-newt.conf`)

Optional flags:

```bash
# also do safe package upgrades
./scripts/ansible_prepare_nuc_newt.sh -e do_full_upgrade=true

# enable UFW defaults + SSH/443 allows (off by default)
./scripts/ansible_prepare_nuc_newt.sh -e configure_ufw=true
```

## VM Plan (recommended)

Build one Debian template, clone two VMs (`newt`, `monitoring`), and assign fixed IPs.

Default clone targets:
- `newt` VMID `9100` -> `192.168.5.181/24`
- `monitoring` VMID `9200` -> `192.168.5.182/24`
- gateway `192.168.5.1`

Run in order:

```bash
./scripts/ansible_fix_nuc_repos.sh
./scripts/ansible_build_nuc_debian_template.sh
./scripts/ansible_clone_nuc_edge_vms.sh
./scripts/ansible_validate_nuc_vms_network.sh
./scripts/ansible_prepare_nuc_vms.sh
```

Teardown and rebuild from clean slate:

```bash
CONFIRM_NUKE_NUC_VMS=YES ./scripts/ansible_teardown_nuc_vms.sh
./scripts/ansible_clone_nuc_edge_vms.sh
./scripts/ansible_validate_nuc_vms_network.sh
./scripts/ansible_prepare_nuc_vms.sh
```

Notes:
- `ansible_clone_nuc_edge_vms.sh` auto-loads `~/.ssh/id_ed25519.pub` (or `id_rsa.pub`) into cloud-init.
- clone playbook uses network defaults from `ops/newt_install/ansible/inventory/group_vars/nuc_vms.yml`.
- VM guest inventory scaffold: `ops/newt_install/ansible/inventory/nuc_vms.ini`
- `ansible_validate_nuc_vms_network.sh` is the network/DNS preflight gate.
- `ansible_prepare_nuc_vms.sh` installs/enables `qemu-guest-agent` on both VMs.
- `ansible_prepare_nuc_vms.sh` auto-refreshes SSH host keys for cloned VM IPs (set `SKIP_HOSTKEY_REFRESH=1` to skip).

One-shot converge for newt only (network fix + validation + guest-agent + snapshot-if-missing):

```bash
./scripts/ansible_converge_newt_baseline.sh
```

Optional runtime override:

```bash
NUC_VM_GATEWAY=192.168.5.1 NUC_VM_DNS=192.168.5.1 ./scripts/ansible_converge_newt_baseline.sh
```

## Snapshot Automation

Create a phase snapshot for both VMs:

```bash
./scripts/ansible_snapshot_edge_vms.sh --name baseline-clean --description "Post-clone baseline"
```

Create a snapshot only for `newt`:

```bash
./scripts/ansible_snapshot_edge_vms.sh --name post-newt-bootstrap --targets newt
```

Require a parent snapshot to exist first:

```bash
./scripts/ansible_snapshot_edge_vms.sh --name phase-2 --expected-parent baseline-clean
```
