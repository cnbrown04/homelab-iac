## Caleb's TODO List

- [ ]


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


### Service Checklist
- [ ] Termix (SSO BACKED)
- [x] Glance Dashboard
- [ ] Jellyfin
- [ ] Arr-stack (SSO BACKED)
- [x] Audiobookshelf
