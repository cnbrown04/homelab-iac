# The Pantheon target

This OpenTofu root manages resources on the four-node `pantheon` cluster. Its
nodes are `gaia`, `hyperion`, `tartarus`, and `theia`. It has its own state.

`vms.tf` lists the VMs, and `containers.tf` lists the containers. Each entry
names the node that runs it. To add a guest, add one entry to a map. Do not
write a new resource block. On 28 September 2026 the cluster had no guest.

Run a plan from the root of the repository:

```sh
source scripts/tofu-env.sh pantheon
cd tofu/targets/pantheon
tofu plan
```

The provider uses the tailnet address of `gaia`. Each node serves the API for
the whole cluster. If `gaia` is down, use a different node:

```sh
export TF_VAR_proxmox_endpoint=https://100.64.0.2:8006/
```
