# The Atlas target

This OpenTofu root manages the standalone Proxmox VE node `atlas`. It has its
own state.

`vms.tf` lists the VMs as data. To add a VM, add one entry to the map. Do not
write a new resource block.

| Entry | VMID | The VM |
| --- | --- | --- |
| `haos` | `100` | Home Assistant OS. OpenTofu imported it on 28 September 2026. |

Run a plan from the root of the repository:

```sh
source scripts/tofu-env.sh atlas
cd tofu/targets/atlas
tofu plan
```

The provider uses the tailnet address of `atlas`. See `provider.tf`.
