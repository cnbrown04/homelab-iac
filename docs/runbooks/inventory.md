# Inventory of the homelab

This document records the hosts, the versions, and the workloads. The owner gave
these facts on 21 September 2026. Check a fact again if it looks old.

## The Proxmox VE hosts

| Host | Role | Cluster | `pve-manager` | Kernel |
| --- | --- | --- | --- | --- |
| `tartarus` | cluster node | `pantheon` | 9.2.20 | 7.0.14-17-pve |
| `prometheus` | cluster node | `pantheon` | 9.2.20 | 7.0.14-17-pve |
| `hyperion` | cluster node | `pantheon` | 9.2.20 | 7.0.14-17-pve |
| `helios` | cluster node | `pantheon` | 9.2.20 | 7.0.14-17-pve |
| `atlas` | standalone node | none | 9.2.20 | 7.0.14-17-pve |

The full version string is `pve-manager/9.2.20/49318c671b82f31e`.

The cluster `pantheon` is the `pve-cluster` target. The host `atlas` is the
`pve-standalone` target.

### A change comes to `prometheus`

The owner installs Proxmox VE again on `prometheus` soon. The new name of the
host is `gaia`.

Warning: a new install deletes the workloads on the host. Do not import a
workload from `prometheus` into the OpenTofu state before the new install is
complete.

## The VPS hosts

| Host | Panel | Status |
| --- | --- | --- |
| RackNerd VPS | SolusVM, with the name NerdVM | in use |
| DediRock VPS | vPanel | the owner tests it now, so do not work on it |

## The workloads

| Workload | Host | Type |
| --- | --- | --- |
| Talos cluster, three nodes | `prometheus` | VM |
| TrueNAS | `prometheus` | VM |
| Home Assistant | `atlas` | VM |
| CrowdSec, Fail2ban, Pangolin, and more | RackNerd VPS | software on the host |

Every workload in the `pantheon` cluster is on `prometheus` now. No workload is
on `tartarus`, `hyperion`, or `helios`.

Note: the exact type of each workload on `atlas` and `prometheus` is not
confirmed. Run `qm list` and `pct list` on the host to get the identity number
and the type of each one. Record the result here before an import.
