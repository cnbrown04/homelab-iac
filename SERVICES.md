# The service map

Start from a service name. Each row gives the host, the guest or the cluster,
and the file that defines the service.

`ansible/inventory/hosts.yml` defines the hosts. `none` in Guest or cluster
means the service runs on the host. `none` in Public name means the files set
no public name.

## The hosts

`atlas` is a standalone Proxmox host. `ansible/inventory/hosts.yml` puts
`gaia`, `hyperion`, `tartarus`, and `theia` in `pantheon`. `hermes` is the
public VPS. `typhon` is the Kubernetes cluster of `pantheon`.

`tofu/targets/pantheon/vms.tf` has no guest on `tartarus` or `theia`.
`tofu/targets/atlas/containers.tf` defines no container.
`tofu/targets/pantheon/containers.tf` defines no container.

## The guests

The file in each row defines that guest.

| Guest | Host | Cluster | File |
| --- | --- | --- | --- |
| `haos-18.2` | `atlas` | none | `tofu/targets/atlas/vms.tf` |
| `typhon-cp-1` | `gaia` | `typhon` | `tofu/targets/pantheon/vms.tf` |
| `typhon-w-1` | `gaia` | `typhon` | `tofu/targets/pantheon/vms.tf` |
| `typhon-w-2` | `gaia` | `typhon` | `tofu/targets/pantheon/vms.tf` |
| `typhon-w-3` | `hyperion` | `typhon` | `tofu/targets/pantheon/vms.tf` |
| `typhon-w-4` | `hyperion` | `typhon` | `tofu/targets/pantheon/vms.tf` |

## The services on `hermes`

`ansible/playbooks/headscale.yml` applies Headscale and Headplane.
`ansible/playbooks/hermes.yml` applies the other services in the table below.
The settings are in `ansible/inventory/host_vars/hermes/main.yml`.
`hermes_compose_stacks` in that file is empty.

The roles deploy the Compose files for Dockge, Headplane, Pangolin, and
Pocket ID. The Compose file of Pangolin defines Gerbil and Traefik. The units
for restic are `backup.service` and `backup.timer`.

| Service | Public name | Host | Guest or cluster | File |
| --- | --- | --- | --- | --- |
| `CrowdSec` (`crowdsec`) | none | `hermes` | none | `ansible/roles/crowdsec/tasks/main.yml` |
| `crowdsec-firewall-bouncer` | none | `hermes` | none | `ansible/roles/crowdsec/tasks/main.yml` |
| `Docker` (`docker`) | none | `hermes` | none | `ansible/roles/docker/tasks/main.yml` |
| `Dockge` | `dockge.buildwithcaleb.com` | `hermes` | none | `ansible/stacks/dockge/compose.yaml` |
| `Fail2ban` (`fail2ban`) | none | `hermes` | none | `ansible/roles/fail2ban/tasks/main.yml` |
| `Gerbil` | none | `hermes` | none | `ansible/stacks/pangolin/compose.yaml` |
| `Headplane` | `headplane.buildwithcaleb.com` | `hermes` | none | `ansible/stacks/headplane/compose.yaml` |
| `Headscale` | `vpn.buildwithcaleb.com` | `hermes` | none | `ansible/roles/headscale/tasks/main.yml` |
| `Pangolin` | `pangolin.buildwithcaleb.com` | `hermes` | none | `ansible/stacks/pangolin/compose.yaml` |
| `Pocket ID` (`pocket-id`) | `auth.buildwithcaleb.com` | `hermes` | none | `ansible/stacks/pocket-id/compose.yaml` |
| `restic` | none | `hermes` | none | `ansible/roles/backup/tasks/main.yml` |
| `Traefik` | none | `hermes` | none | `ansible/stacks/pangolin/compose.yaml` |
| `UFW` | none | `hermes` | none | `ansible/roles/ufw/tasks/main.yml` |

## The services on the Proxmox hosts

`ansible/playbooks/proxmox_nodes.yml` applies the services in the table below
on `atlas`, `gaia`, `hyperion`, `tartarus`, and `theia`.
`ansible/playbooks/hermes.yml` applies `unattended-upgrades` on `hermes`.

`ansible/playbooks/proxmox_nodes.yml` applies `zfs_nfs` for a host with
`zfs_nfs_pool`. Only `gaia` has `zfs_nfs_pool`. The exports are in
`ansible/inventory/host_vars/gaia/main.yml`.

| Service | Public name | Host | Guest or cluster | File |
| --- | --- | --- | --- | --- |
| `NFS` (`nfs-server`) | none | `gaia` | none | `ansible/roles/zfs_nfs/tasks/main.yml` |
| `Proxmox web UI` | `<host>.vnet.buildwithcaleb.com` | `atlas`, `gaia`, `hyperion`, `tartarus`, `theia` | none | `ansible/roles/proxmox_web/tasks/main.yml` |
| `pve-https-redirect` | none | `atlas`, `gaia`, `hyperion`, `tartarus`, `theia` | none | `ansible/roles/proxmox_web/tasks/redirect.yml` |
| `Tailscale` (`tailscaled`) | none | `atlas`, `gaia`, `hyperion`, `tartarus`, `theia` | none | `ansible/roles/tailscale/tasks/main.yml` |
| `unattended-upgrades` | none | `atlas`, `gaia`, `hyperion`, `tartarus`, `theia`, `hermes` | none | `ansible/roles/unattended_upgrades/tasks/main.yml` |

## The service on `atlas`

The VM name is `haos-18.2`. The key in `vms.tf` is `haos`.

| Service | Public name | Host | Guest or cluster | File |
| --- | --- | --- | --- | --- |
| `Home Assistant` | none | `atlas` | `haos-18.2` | `tofu/targets/atlas/vms.tf` |

## The services on `typhon`

Each guest of `typhon` is on `gaia` or `hyperion`.

Jellyfin sets a limit of one `gpu.intel.com/i915` device.
`typhon-cluster/infrastructure/controllers/intel-gpu-plugin/plugin.yaml`
selects the label `homelab/gpu=intel`. `typhon-cluster/talos/talconfig.yaml`
sets that label on `typhon-w-3`. `tofu/targets/pantheon/vms.tf` puts
`typhon-w-3` on `hyperion`.

### The apps

`typhon-cluster/apps/kustomization.yaml` has one entry for each app.
`typhon-cluster/flux/apps.yaml` deploys the apps.
`typhon-cluster/talos/talconfig.yaml` sets `allowSchedulingOnControlPlanes`
to false. An app runs on a worker. The workers are `typhon-w-1` and
`typhon-w-2` on `gaia`, and `typhon-w-3` and `typhon-w-4` on `hyperion`.

`gluetun` is a container in the qBittorrent deployment.

| Service | Public name | Host | Guest or cluster | File |
| --- | --- | --- | --- | --- |
| `Audiobookshelf` | `audiobooks.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/audiobookshelf/deployment.yaml` |
| `Chaptarr` | `chaptarr.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/chaptarr/deployment.yaml` |
| `Glance` | `home.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/glance/deployment.yaml` |
| `gluetun` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/qbittorrent/deployment.yaml` |
| `Jackett` | `jackett.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/jackett/deployment.yaml` |
| `Jellyfin` | `jellyfin.buildwithcaleb.com` | `hyperion` | `typhon-w-3` (`typhon`) | `typhon-cluster/apps/jellyfin/deployment.yaml` |
| `Prowlarr` | `prowlarr.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/prowlarr/deployment.yaml` |
| `qBittorrent` | `qbittorrent.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/qbittorrent/deployment.yaml` |
| `Radarr` | `radarr.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/radarr/deployment.yaml` |
| `Seerr` | `seerr.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/seerr/deployment.yaml` |
| `Sonarr` | `sonarr.buildwithcaleb.com` | `gaia` or `hyperion` | `typhon` | `typhon-cluster/apps/sonarr/deployment.yaml` |

### The base services

`typhon-cluster/infrastructure/controllers/kustomization.yaml` has one entry
for each controller. `typhon-cluster/flux/infrastructure.yaml` deploys the
controllers and the configs.

`typhon-cluster/infrastructure/configs/storage/nfs-lethe.yaml` uses the
address of `gaia` on VLAN 20.

| Service | Public name | Host | Guest or cluster | File |
| --- | --- | --- | --- | --- |
| `Cilium` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/infrastructure/controllers/cilium/helmrelease.yaml` |
| `csi-driver-nfs` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/infrastructure/controllers/csi-driver-nfs/helmrelease.yaml` |
| `Flux` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/flux/sync.yaml` |
| `Gateway` `main` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/infrastructure/configs/cilium/gateway.yaml` |
| `intel-gpu-plugin` | none | `hyperion` | `typhon-w-3` (`typhon`) | `typhon-cluster/infrastructure/controllers/intel-gpu-plugin/plugin.yaml` |
| `local-path-provisioner` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/infrastructure/controllers/local-path-provisioner/helmrelease.yaml` |
| `metrics-server` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/infrastructure/controllers/metrics-server/helmrelease.yaml` |
| `nfs-lethe` | none | `gaia` | `typhon` | `typhon-cluster/infrastructure/configs/storage/nfs-lethe.yaml` |
| `pangolin-wireguard` | none | `gaia` or `hyperion` | `typhon` | `typhon-cluster/infrastructure/controllers/pangolin-wireguard/deployment.yaml` |
