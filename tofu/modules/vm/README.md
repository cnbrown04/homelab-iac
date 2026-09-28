# The VM module

One Proxmox VM, with the `bpg/proxmox` provider. A target lists its VMs as data
and calls this module once for each VM. Keep target data out of this module.

The module sets the values that differ between VMs. The provider defaults cover
the rest.

To take an existing VM into the state, copy its values from `qm config <VMID>`
into the target. Then import it with an `import` block, and run `tofu plan`
until it shows no change. Two values need care:

- `cpu_type`: a VM with no `cpu` line runs `qemu64`. Set `cpu_type = "qemu64"`
  for such a VM.
- `tablet_device`: set it to `false` when `qm config` shows `tablet: 0`.
