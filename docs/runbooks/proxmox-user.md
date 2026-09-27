# The user for the Proxmox provider

This runbook records the current SSH requirements for `bpg/proxmox`. The
provider's standard VM and container operations use the Proxmox API. SSH is
optional. Use only the SSH permissions for a feature that a target needs.

## API access

The provider needs API access for normal VM and container work. Build the API
role from the resources in the target and the current Proxmox permission docs.
Do not copy the full role example from the provider overview. The provider says
that example can grant more rights than most uses need.

API permissions and SSH permissions are separate. This runbook records the SSH
requirements only.

## SSH access

The provider needs SSH for these operations:

- Upload snippets or some file types with `proxmox_virtual_environment_file`.
- Import a local disk with `source_file.path` on
  `proxmox_virtual_environment_vm`.
- Set `idmap` entries on `proxmox_virtual_environment_container`.

Standard VM and container create, change, and delete operations do not need SSH.
Use API-backed disk imports such as `import_from` when possible.

When a target needs SSH, use a dedicated non-root user with passwordless `sudo`
on each Proxmox node that the target can access. The provider first tests the
SSH connection with `pvesm apiinfo`. The documented narrow rule is:

```text
<user> ALL=(root) NOPASSWD: /usr/sbin/pvesm apiinfo
```

Add a rule for a feature only when the target uses that feature:

| Feature | Additional documented command |
| --- | --- |
| Snippet upload | `/usr/bin/tee /var/lib/vz/snippets/[a-zA-Z0-9_][a-zA-Z0-9_.-]*` |
| LXC `idmap` | `/usr/bin/sed -i * /etc/pve/lxc/*.conf` and `/usr/bin/tee -a /etc/pve/lxc/*.conf` |
| Local disk import with `source_file.path` | Check the provider version docs before use; do not grant broad `qm` or `pvesm` access |

The provider warns that full `sudo` access to `qm` or `pvesm` gives root-level
access. It also warns that broad `tee` wildcards can allow path traversal. Do not
use broad wildcards or `NOPASSWD: ALL`.

The provider docs show wildcards in the `idmap` rules. Do not add those rules
until their sudoers argument matching has a security review. Use `import_from`
instead of local disk import when the target can use the API-backed method.

If a target uses only API-backed resources, do not configure SSH or add a sudoers
file for the provider.

## Sources

- [Provider 0.114.0 overview and SSH requirements](https://github.com/bpg/terraform-provider-proxmox/blob/v0.114.0/docs/index.md#ssh-connection)
- [Proxmox VE privileges](https://pve.proxmox.com/pve-docs/pveum.1.html#_privileges)
