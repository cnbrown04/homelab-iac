## Caleb's TODO List

- [ ]


### Hosts
- [ ] Add the RackNerd VPS iris to Ansible (scripts/vps-harden.sh, hosts.yml, a play like hermes). It hosts the websites and the personal projects. It has 1.5 GiB of RAM and 1 vCPU, so keep each service small.


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


### Cluster
- [ ] Find a web page to manage Flux in typhon, with the Pocket ID login. Compare these:
  - Capacitor (gimlet-io/capacitor, Apache-2.0): a general UI for Flux. The last change was in February 2026, so check that it is maintained, and check the runtime of its backend.
  - The Flux Web UI of the Flux Operator (controlplaneio-fluxcd/flux-operator, Go, AGPL-3.0): active. typhon does not use the Flux Operator now, so this needs a move to the operator first.
  - Weave GitOps: now a community project. Check that it still gets releases.
  - Headlamp with its Flux plugin: a general Kubernetes UI.


### Databases
- [ ] Manage the PlanetScale Postgres in code, not by hand. Today the owner made the database kaneo with psql.
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
