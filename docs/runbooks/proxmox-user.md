# The user for the Proxmox provider

This runbook records the current SSH requirements for `bpg/proxmox`. The
provider's standard VM and container operations use the Proxmox API. SSH is
optional. Use only the SSH permissions for a feature that a target needs.

## API access

The provider needs API access for normal VM and container work. Do not copy the
full role example from the provider overview. It has `Permissions.Modify`,
`Realm.Allocate`, and `Sys.Modify`, which give admin access.

### The role `IaCProvisioner`

The role has the privileges below and no others. The names come from
`src/PVE/AccessControl.pm` in `pve-access-control` (commit `dff26b4586`,
17 September 2026), which Proxmox VE 9 uses.

| Privilege | The reason |
| --- | --- |
| `VM.Allocate` | Create and delete a VM or a container. |
| `VM.Audit` | Read the configuration and the status. |
| `VM.Clone` | Clone a template. |
| `VM.Config.CDROM`, `VM.Config.CPU`, `VM.Config.Cloudinit`, `VM.Config.Disk`, `VM.Config.HWType`, `VM.Config.Memory`, `VM.Config.Network`, `VM.Config.Options` | Change each part of the configuration. |
| `VM.PowerMgmt` | Start, stop, and reboot. |
| `VM.Migrate` | Move a guest to a different node. Only a cluster needs it. |
| `VM.GuestAgent.Audit` | Read the IP addresses from the QEMU guest agent. |
| `Datastore.AllocateSpace` | Make a disk on a storage. |
| `Datastore.AllocateTemplate` | Download an ISO or a container template. |
| `Datastore.Audit` | Read the storage. |
| `SDN.Audit`, `SDN.Use` | See and use a bridge. Without them, Proxmox VE 9 hides the bridges. |
| `Sys.Audit` | Read the node status and the version. |

### The user and the token

Each API endpoint has its own user database: `atlas` has one, and `pantheon`
has one. Run these commands one time on each endpoint, as root. On `atlas`:

```sh
ssh -t iac-admin@10.0.1.124 sudo bash
pveum role add IaCProvisioner --privs "VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.PowerMgmt VM.Migrate VM.GuestAgent.Audit Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit SDN.Audit SDN.Use Sys.Audit"
pveum user add tofu@pve --comment "OpenTofu, homelab-iac"
pveum acl modify / --users tofu@pve --roles IaCProvisioner
pveum user token add tofu@pve homelab-iac --privsep 0 --comment "homelab-iac"
```

The user is in the realm `pve`, so it has no Linux account and no password.
The last command shows the token secret one time. The full token is
`tofu@pve!homelab-iac=<secret>`. Store it as `atlas_api_token` or
`pantheon_api_token` in `secrets/tofu.sops.yaml`. See
`docs/runbooks/tofu-state.md`.

On 28 September 2026 the owner made the user and the token on `atlas` and on
the `pantheon` cluster (through `gaia`).

A guest with a raw USB or PCI device needs `root@pam` to change that device.
The token can read the guest and change the other parts.

API permissions and SSH permissions are separate. The rest of this runbook
records the SSH requirements.

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
