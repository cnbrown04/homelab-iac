# The LXC module

One Proxmox container, with the `bpg/proxmox` provider. A target lists its
containers as data and calls this module once for each container. Keep target
data out of this module.

The API token is not `root@pam`, so these limits apply:

- The container is unprivileged. Only `root@pam` can make a privileged
  container.
- `nesting` is the only feature flag. The other flags need `root@pam`.
- A mount point uses a storage volume. A bind mount of a host path needs
  `root@pam`.

Use lowercase tags. Proxmox makes each tag lowercase, and an uppercase tag
shows a change in each plan.
