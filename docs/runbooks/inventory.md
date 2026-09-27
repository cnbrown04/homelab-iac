# Inventory of the homelab

This document records the hosts, the versions, and the workloads. The owner
updated the host and workload facts on 26 September 2026. The Proxmox versions
for `gaia` and `theia` were checked on 26 September 2026. The other nodes were
last checked on 21 September 2026.

## The Proxmox VE hosts

| Host | Role | Cluster | `pve-manager` | Kernel |
| --- | --- | --- | --- | --- |
| `tartarus` | cluster node | `gaia` | 9.2.20 | 7.0.14-17-pve |
| `gaia` | cluster node | `gaia` | 9.2.20 | 7.0.14-19-pve |
| `hyperion` | cluster node | `gaia` | 9.2.20 | 7.0.14-17-pve |
| `theia` | cluster node | `gaia` | 9.2.20 | 7.0.14-19-pve |
| `atlas` | standalone node | none | 9.2.20 | 7.0.14-17-pve |

The full version string is `pve-manager/9.2.20/49318c671b82f31e`. The owner
confirmed this version on `gaia` and `theia` on 26 September 2026.

The cluster `gaia` is the `pve-cluster` target. The host `atlas` is the
`pve-standalone` target.

The owner reinstalled Proxmox VE on `prometheus` and renamed it `gaia`. The owner
also renamed `helios` to `theia`. The Talos cluster and TrueNAS VM were deleted.
The cluster now has no recorded workloads.

## The VPS hosts

| Host | Panel | Status |
| --- | --- | --- |
| RackNerd VPS | SolusVM, with the name NerdVM | in use; already hardened |
| DediRock VPS | vPanel | needs hardening; planned host for services outside the homelab |

## The workloads

| Workload | Host | Type |
| --- | --- | --- |
| Home Assistant (`haos-18.2`, VMID `100`) | `atlas` | VM, running |
| CrowdSec, Fail2ban, Pangolin, and more | RackNerd VPS | software on the host |
| Services outside the homelab | DediRock VPS | planned; Dockage is preferred but not chosen |

No workload is recorded on the `gaia` cluster. The Talos cluster and TrueNAS VM
were deleted before the `prometheus` reinstall.

On 26 September 2026, `qm list` showed VMID `100`, name `haos-18.2`, running.
`pct list` showed no containers. Import VMID `100` into the OpenTofu state
before any apply.
