<div align="center">

# homelab-iac
## this is my homelab infrastrucure defined as code

| Hypervisor                                                                                      | OS                                                                                                                                                                                                                                                                                                                                                                                             | Tools                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Networking                                                                                              | Misc. Automations                                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [![Proxmox](https://img.shields.io/badge/-Proxmox-black?logo=Proxmox)](https://www.proxmox.com) | [![Talos](https://img.shields.io/badge/Talos-black?&logo=talos)](https://www.talos.dev/) [![Ubuntu](https://img.shields.io/badge/Ubuntu-black?&logo=ubuntu&logoColor=red)](https://releases.ubuntu.com/noble/) | [![Docker](https://img.shields.io/badge/-Docker-black?logo=docker)](https://www.docker.com/) [![Kubernetes](https://img.shields.io/badge/-Kubernetes-black?logo=kubernetes)](https://kubernetes.io/) [![Renovate](https://img.shields.io/badge/-Renovate-black?logo=renovate&logoColor=blue)](https://github.com/renovatebot/renovate) [![OpenTofu](https://img.shields.io/badge/-OpenTofu-black?logo=opentofu)](https://opentofu.org/) [![Ansible](https://img.shields.io/badge/-Ansible-black?logo=ansible&logoColor=red)](https://www.ansible.com/) [![Flux](https://img.shields.io/badge/-Flux-black?logo=flux)](https://fluxcd.io/) | [![Unifi](https://img.shields.io/badge/-Unifi-black?logo=ubiquiti&logoColor=blue)](https://www.ui.com/) | [![Actions](https://img.shields.io/badge/-Actions-black?logo=github&logoColor=white)](https://github.com/features/actions) |

<table>
  <tr>
    <th><code>atlas</code><br><sub>Proxmox</sub></th>
    <th><code>hermes</code><br><sub>VPS</sub></th>
    <th><code>mnemosyne</code><br><sub>VM on gaia</sub></th>
    <th><code>argus</code><br><sub>VM on tartarus</sub></th>
    <th><code>daedalus</code><br><sub>VM on tartarus</sub></th>
    <th><code>typhon</code><br><sub>Kubernetes</sub></th>
  </tr>
  <tr>
    <td valign="top" align="left">
      <a href="https://www.home-assistant.io/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg" width="20" height="20" alt=""> Home Assistant</a><br>
    </td>
    <td valign="top" align="left">
      <a href="https://headscale.net/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/headscale.svg" width="20" height="20" alt=""> Headscale</a><br>
      <a href="https://pangolin.net/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pangolin.svg" width="20" height="20" alt=""> Pangolin</a><br>
      <a href="https://pocket-id.org/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pocket-id.svg" width="20" height="20" alt=""> Pocket ID</a><br>
      <a href="https://github.com/tale/headplane"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/headplane.svg" width="20" height="20" alt=""> Headplane</a><br>
      <a href="https://dockge.kuma.pet/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dockge.svg" width="20" height="20" alt=""> Dockge</a><br>
    </td>
    <td valign="top" align="left">
      <a href="https://www.samba.org/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/samba-server.svg" width="20" height="20" alt=""> Samba</a><br>
      <a href="https://opencloud.eu/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/open-cloud.svg" width="20" height="20" alt=""> OpenCloud</a><br>
    </td>
    <td valign="top" align="left">
      <a href="https://wazuh.com/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/wazuh.svg" width="20" height="20" alt=""> Wazuh</a><br>
    </td>
    <td valign="top" align="left">
      <a href="https://www.anthropic.com/claude-code"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/claude-ai.svg" width="20" height="20" alt=""> Claude Code</a><br>
      <a href="https://opencode.ai/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/opencode.svg" width="20" height="20" alt=""> opencode</a><br>
      <a href="https://neovim.io/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/neovim.svg" width="20" height="20" alt=""> Neovim</a><br>
      <a href="https://mise.jdx.dev/"><img src="https://mise.jdx.dev/logo.svg" width="20" height="20" alt=""> mise</a><br>
    </td>
    <td valign="top" align="left">
      <a href="https://fluxcd.io/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/flux-cd.svg" width="20" height="20" alt=""> Flux</a><br>
      <a href="https://github.com/glanceapp/glance"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/glance.svg" width="20" height="20" alt=""> Glance</a><br>
      <a href="https://jellyfin.org/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg" width="20" height="20" alt=""> Jellyfin</a><br>
      <a href="https://www.audiobookshelf.org/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/audiobookshelf.svg" width="20" height="20" alt=""> Audiobookshelf</a><br>
      <a href="https://github.com/seerr-team/seerr"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/seerr.svg" width="20" height="20" alt=""> Seerr</a><br>
      <a href="https://sonarr.tv/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg" width="20" height="20" alt=""> Sonarr</a><br>
      <a href="https://radarr.video/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg" width="20" height="20" alt=""> Radarr</a><br>
      <a href="https://prowlarr.com/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg" width="20" height="20" alt=""> Prowlarr</a><br>
      <a href="https://hub.docker.com/r/chaptarr/chaptarr"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/chaptarr.svg" width="20" height="20" alt=""> Chaptarr</a><br>
      <a href="https://github.com/Jackett/Jackett"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jackett.svg" width="20" height="20" alt=""> Jackett</a><br>
      <a href="https://www.qbittorrent.org/"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg" width="20" height="20" alt=""> qBittorrent</a><br>
      <a href="https://github.com/Termix-SSH/Termix"><img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/termix.svg" width="20" height="20" alt=""> Termix</a><br>
    </td>
  </tr>
</table>

</div>

## Quick Overview
So this is all of my IaC stuff for my homelab.

I have a total of five physical machines in the homelab itself, plus my personal devices. The exact machines and what they run will be further down.

Everything here uses IaC and I prefer not to use [Docker](https://www.docker.com/) wherever I can use [Kubernetes](https://kubernetes.io/) instead, but kubernetes is a fickle beast that doesn't behave well sometimes. I'm forced to use Docker on things like my VPS and some other places where kubernetes doesn't make a lot of sense. With that, all of my kubernetes nodes are virtualized inside of [Proxmox](https://www.proxmox.com/). You might think "but Caleb why would you have kubernetes and Proxmox at the same time, wouldn't that lead to fights with HA?" and you'd be right. I have HA disabled on the kubernetes nodes to reduce the chance that I'd run into issues with kubernetes nodes migrating to other proxmox nodes etc. Even with that my storage lives on a single proxmox node so it's my single point of failure regardless unless I want to setup something like [Ceph](https://ceph.io/)... which I don't want to do.

To automate infrastructure updates and deployments I am using [GitHub Actions](https://github.com/features/actions) which trigger based on specific changes in this repository. You can look at the actions runs to see that there are some things called `pantheon`, `atlas`, `hermes` and so on; we'll get into that later.

## Security
For security I've been lazy and honestly try to make things as easy as possible for myself in regards to this. Some of the tools I use are as follows:

- [GitGuardian](https://www.gitguardian.com/) for if I leak a secret on accident.
- [Wazuh](https://wazuh.com/) for SIEM / Alerting
- [SOPS](https://getsops.io/) for encrypting secrets so I can just be lazy and commit them here instead of running a seperate secret manager like [Bitwarden](https://bitwarden.com/) or [OpenBao](https://openbao.org/).

VPS's specifically get special treatment since I use those for network ingress through [WireGuard](https://www.wireguard.com/) tunnels into my network. I use [Pangolin](https://pangolin.net/) for this as it acts as a reverse proxy as well as allows me to create "[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)" esque endpoints for services I don't want to fool around with. On these VPS's they're hardened with [CrowdSec](https://www.crowdsec.net/), [Fail2Ban](https://github.com/fail2ban/fail2ban), as well as having all password login disabled in favor of SSH keys. I also prefer not to leave my personal SSH key on the VPS's and instead us [opkssh](https://github.com/openpubkey/opkssh) to handle logins throughout my network.

## Monitoring / Observability
Nothin' right now. Working on that.

## Cloud Dependencies
Although I try to self-host everything I can, my infra still relies on the cloud for certain services.

| Service                                                                                 | Use                                                                                                             | Cost           |
| --------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------------- |
| [Proton](https://proton.me/)                                                            | VPN                                                                                                             | ~$85/yr        |
| [GitHub](https://github.com/)                                                           | Hosting this repo and continuous integration/deployments                                                        | Free           |
| [Cloudflare](https://www.cloudflare.com/)                                               | Domains and DNS                                                                                                 | Free           |
| [Dedirock](https://dedirock.com/)                                                       | Primary VPS, `hermes`                                                                                           | $48/yr         |
|                  |                                                                                                                 | Total: ~$11/mo |

## Hardware
yeah so this is the section you're going to be like "why?!?"

<details open>
  <summary><strong>Servers</strong></summary>

| Name         | Device                   | CPU                       | RAM       | Storage           | GPU        | Purpose                                    |
| ------------ | ------------------------ | ------------------------- | --------- | ----------------- | ---------- | ------------------------------------------ |
| **atlas**    | ASRock DeskMini 110      | Intel i5-7600             | 16GB DDR4 | 1TB HDD           | Integrated | Proxmox node (standalone), Home Assistant  |
| **gaia**     | Dell PowerEdge R740      | 2x Intel Xeon Silver 4110 | 64GB DDR4 | 7x 1.2TB HDD      | n/a        | Proxmox node (`pantheon`), NFS storage     |
| **hermes**   | Dedirock VPS             | 2 vCPU (Intel i9-14900K)  | 4GB       | 64GB NVMe         | n/a        | Public VPS, Pangolin, Headscale, Pocket ID |
| **hyperion** | Dell OptiPlex Micro 7010 | Intel i5-13500T           | 16GB DDR4 | 512GB NVMe        | Integrated | Proxmox node (`pantheon`)                  |
| **tartarus** | Dell PowerEdge R740xd    | Intel Xeon Silver 4210    | 32GB DDR4 | 2x 1.92TB SAS SSD | n/a        | Proxmox node (`pantheon`)                  |
| **theia**    | Dell OptiPlex Micro 7020 | Intel i7-14700T           | 16GB DDR5 | 512GB NVMe        | Integrated | Proxmox node (`pantheon`)                  |

</details>

<details open>
  <summary><strong>Networking</strong></summary>

| Name   | Device                  | Purpose         |
| ------ | ----------------------- | --------------- |
| Router | UniFi Dream Machine Pro | Router/Firewall |
| Switch | HP Aruba 2530-24G       | Switch          |

</details>

<details open>
  <summary><strong>Personal</strong></summary>

| Name           | Device      | CPU               | RAM          | Storage   | GPU             | Purpose    |
| -------------- | ----------- | ----------------- | ------------ | --------- | --------------- | ---------- |
| **hephaestus** | Custom      | AMD Ryzen 7 7700X | 32GB DDR5    | 1TB NVMe  | Nvidia RTX 3080 | Primary PC |
|                | MacBook Pro | Apple M1 Max      | 32GB Unified | 512GB SSD | Integrated      | Laptop     |

</details>

