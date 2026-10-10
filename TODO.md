## Caleb's TODO List

- [ ]


### Hosts
- [ ] Add the RackNerd VPS iris to Ansible (scripts/vps-harden.sh, hosts.yml, a play like hermes). It hosts the websites and the personal projects. It has 1.5 GiB of RAM and 1 vCPU, so keep each service small.


### Pipelines and speed
These notes come from the measurements of 7 and 8 October 2026. A check of
hermes went from 73 s to 24 s. A check of all hosts went from 150 s to 68 s.
- [ ] Push the speed changes, then compare the times in GitHub. Before: the job check of ansible took 110 s, and the plan of pantheon took 136 s.
- [ ] Apply proxmox_nodes.yml. It deletes the key "WSL Ubuntu" (SHA256:wgY56...) from iac-admin on the 5 Proxmox nodes. The owner chose to delete it on 8 October 2026.
- [ ] ansible-core deprecates third-party strategy plugins, with no removal date. Read the changelog of each ansible-core bump. If Mitogen stops, delete strategy_plugins and strategy from ansible/ansible.cfg.
- [x] Short commands for the checks: mise run check:hermes, check:proxmox, check:mnemosyne, check:all, lint:ansible, plan:atlas, plan:pantheon.
- [x] The cache of mise in the pipelines uses only the tools of the job (.github/actions/mise-install). A bump of a different tool does not empty it.
- Not changed, with the reason:
  - proxmox_web makes 8 pvesh reads at about 1.4 s each. Each pvesh call starts Perl, so one task with 8 calls is not faster. The nodes run in parallel, so run_once gives no time. Only a parse of the raw files in /etc/pve is faster, and that is fragile. The gain is about 10 s on a playbook that runs by hand.
  - tofu.yml runs the lint (12 s) before the plans. The apply is in the reusable workflow, so it cannot wait for a lint job that runs at the same time. The change needs a new structure for 12 s.
  - stacks.yml has no tags, but hermes_compose_stacks is empty, so the play does nothing.


### Personal website
- [ ] Find a good place for the documentation on the personal website
- [ ] Build the personal website again with a CMS


### Backups
- [ ] Daily etcd snapshot of typhon to R2 (one control plane, so this is urgent)
- [ ] Off-site backup of the important data on lethe to R2 with restic (/lethe/k8s, app backups; decide which media)
- [ ] ZFS snapshots on gaia (for example sanoid)


### Monitoring and logs
- [ ] Uptime check from outside the homelab (for example Gatus or Uptime Kuma on hermes) that pings each node
- [ ] Log store out of typhon: an LXC on atlas with VictoriaLogs (hermes is the other option, but it needs Pangolin)
- [ ] Role journal_upload: send the journal of each Proxmox node to the log store
- [ ] Second network path to the log store for each node (USB Ethernet adapter, or WiFi on its own VLAN), with a host route
- [ ] Self-heal timer on the e1000e nodes: ping the gateway through nic0, reset the NIC after failures
- [ ] Collector for the pod and Talos logs of typhon, to the log store
- [ ] Fix the local mail on the Proxmox nodes: /etc/aliases.db is missing, so postfix defers each mail


### Security
- [ ] Add Wazuh, a security platform. It collects the security events of each host and shows the threats that it finds.
  - Put the Wazuh agent on each host with an Ansible role. Each agent sends its events to one Wazuh server.
  - Choose the host of the server first. The Wazuh indexer needs about 8 GiB of RAM, so a Talos worker or hermes is too small.
- [ ] Get a YubiKey for the break-glass key of iac-admin. iac-admin logs in with opkssh, and Pocket ID runs on hermes. When Pocket ID is down, the break-glass key is the only way for Ansible to log in.
  - Use a FIDO2 key (ed25519-sk), so each login needs a touch of the YubiKey.
  - Keep a second YubiKey with a copy, or a second key in a safe place.
- [ ] Research opkssh, so Termix logs in to the hosts with Pocket ID and short-lived SSH certificates.
  - Termix has an opkssh plugin and ships opkssh v0.16.0. Its config is `/app/data/plugin-data/opkssh/config.yml`, and the redirect URI is `/plugin-api/opkssh/callback`.
  - Each host needs the server part: `AuthorizedKeysCommand`, the files `/etc/opk/providers` and `/etc/opk/auth_id`, and the user `opksshuser`. Do it with an Ansible role, not the install script.
  - Choose the hosts and the Linux user of each host. The Proxmox nodes touch decision 10.


### Cluster
- [x] Find a web page to manage Flux in typhon, with the Pocket ID login. The owner chose the Flux Web UI of the Flux Operator on 10 October 2026. Compare these:
  - Capacitor (gimlet-io/capacitor, Apache-2.0): a general UI for Flux. The last change was in February 2026, so check that it is maintained, and check the runtime of its backend.
  - The Flux Web UI of the Flux Operator (controlplaneio-fluxcd/flux-operator, Go, AGPL-3.0): active. typhon does not use the Flux Operator now, so this needs a move to the operator first.
  - Weave GitOps: now a community project. Check that it still gets releases.
  - Headlamp with its Flux plugin: a general Kubernetes UI.


### Databases
- [ ] Manage the PlanetScale Postgres in code, not by hand. Today the owner makes each database by hand with psql.
  - The provider planetscale/planetscale (1.12.0) has postgres_branch, postgres_branch_role (one role for each app, not the default role), postgres_backup_policy, and postgres_bouncer.
  - The databases and the extensions inside the branch need a second tool: the OpenTofu provider of PostgreSQL, or the Ansible collection community.postgresql (5.0.0).
  - Decision 2 in AGENTS.md says that OpenTofu manages Proxmox guests only. Choose the tool first, and change the decision if OpenTofu gets the job.
  - Put the password of each role in SOPS, and give each app its own role.


### Service Checklist
- [ ] Termix (SSO BACKED)
- [x] Glance Dashboard
- [x] Jellyfin
- [x] Arr-stack (SSO BACKED)
- [x] Audiobookshelf


### Files
- [ ] Check Spacedrive when its iOS app is in the App Store (the beta is planned for 1 November 2026). It can give the shares in /lethe/shares to the iOS Files app with no tailnet. Its server is Rust.
- [ ] Look again at self-hosting MACRO (macro-inc/macro, Rust, AGPL-3.0). In October 2026 it had no published images, about 25 services, Kafka, OpenSearch, and Redis, and it needed FusionAuth and LiveKit licenses. The FAQ says that self-hosting gets easier later in 2026.
- [ ] Try Taildrive on mnemosyne after Headscale 0.30 (it adds nodeAttrs and app grants). Give drive:share to tag:nas and drive:access to the devices of the owner, plus a tailscale.com/cap/drive grant for each share. Check that the files get user 3000. Taildrive is alpha and needs the tailnet, like SMB.
