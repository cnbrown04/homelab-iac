# Inventory of the homelab

This document records the hosts, the versions, and the workloads. The owner
updated the host and workload facts on 27 September 2026. The Proxmox versions
for `gaia` and `theia` were checked on 26 September 2026. The other nodes were
last checked on 21 September 2026.

## The Proxmox VE hosts

| Host | LAN address | Tailnet address | Role | Cluster | `pve-manager` | Kernel |
| --- | --- | --- | --- | --- | --- | --- |
| `tartarus` | `10.0.1.113` | `100.64.0.4` | cluster node | `pantheon` | 9.2.20 | 7.0.14-17-pve |
| `gaia` | `10.0.1.120` | `100.64.0.5` | cluster node | `pantheon` | 9.2.20 | 7.0.14-19-pve |
| `hyperion` | `10.0.1.101` | `100.64.0.2` | cluster node | `pantheon` | 9.2.20 | 7.0.14-17-pve |
| `theia` | `10.0.1.131` | `100.64.0.1` | cluster node | `pantheon` | 9.2.20 | 7.0.14-19-pve |
| `atlas` | `10.0.1.124` | `100.64.0.3` | standalone node | none | 9.2.20 | 7.0.14-17-pve |

Headscale gives each tailnet node a MagicDNS name,
`<hostname>.vnet.buildwithcaleb.com`, for example
`gaia.vnet.buildwithcaleb.com`. The Proxmox nodes join with
`--accept-dns=false`, so the nodes do not use MagicDNS. Other devices on the
tailnet use it.

The full version string is `pve-manager/9.2.20/49318c671b82f31e`. The owner
confirmed this version on `gaia` and `theia` on 26 September 2026.

The `pantheon` cluster uses the `pantheon` target. The standalone host `atlas`
uses the `atlas` target.

The owner reinstalled Proxmox VE on `prometheus` and renamed it `gaia`. The owner
also renamed `helios` to `theia`. The Talos cluster and TrueNAS VM were deleted.
The cluster now has no recorded workloads.

## The host `hermes`

| Host | Address | SSH user | SSH port | Panel | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `hermes` | `192.255.220.7` | `caleb` | `22` | vPanel | hardened; Ansible-managed |

## The workloads

| Workload | Host | Type |
| --- | --- | --- |
| Home Assistant (`haos-18.2`, VMID `100`) | `atlas` | VM, running |
| CrowdSec and Fail2ban | `hermes` | running |
| Pangolin Enterprise Edition | `hermes` | running; Ansible deploys it |
| Headscale control server (0.29.3) | `hermes` | running; Ansible deploys it |
| Headplane (0.7.1) | `hermes` | planned; Ansible deploys it |
| Pocket ID (2.16.0) | `hermes` | running at `auth.buildwithcaleb.com`; a Pangolin resource |
| Dockge (1.5.0) | `hermes` | planned; Ansible deploys it behind the Pangolin login |
| Docker Compose stacks | `hermes` | planned; Ansible deploys them |

No workload is recorded on the `pantheon` cluster. The Talos cluster and TrueNAS VM
were deleted before the `prometheus` reinstall.

On 26 September 2026, `qm list` showed VMID `100`, name `haos-18.2`, running.
`pct list` showed no containers. Import VMID `100` into the OpenTofu state
before any apply.
