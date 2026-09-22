# The risks, and the answer to each one

Step 1 of the build order says: verify each risk, then record the answer. This
document holds the answers. The risks come from `context/handoff-original.md`.

Git ignores `context/`, but git keeps this document. This document is the record
that lasts.

## 1. The version of Proxmox VE — closed

Every one of the five nodes runs `pve-manager/9.2.20`. The kernel is
`7.0.14-17-pve`.

The version is on the 9.x line. The bpg provider supports 9.x in full. No node
runs 7.x or 8.x, so no feature has a limit for that reason. See
`docs/runbooks/inventory.md` for the table.

Caution: the kernel number is 7.0.14-17, but the kernel number is not the
version of Proxmox VE. Read `pve-manager` only.

## 2. The 0.x line of the provider — open, and it stays open

The provider has a 0.x version number. Some minor releases changed behaviour and
broke a configuration. The releases 0.102.0 and 0.109.0 are two examples.

Action: read the changelog for every version bump of the provider. A Renovate
pull request for the provider needs a human to read the changelog.

## 3. The version number of the provider — open

The handoff names 0.113.1, but the source was a search result. Another page
showed 0.110.0.

Action: run `tofu init` in a target, then read `.terraform.lock.hcl`. Record the
version here. Do this in step 2 or step 5.

## 4. The way a runner joins the network — open, and it changed

The owner replaced Tailscale with Headscale on 21 September 2026. Headscale is
an open-source control server. The client software of Tailscale stays the same,
but the control server is not the service of Tailscale.

Two facts are open:

- The handoff names `tailscale/github-action@v4`, but the source was a search
  snippet. The correct tag is not confirmed.
- The action logs in to the service of Tailscale by default. A custom control
  server needs a login server option. The method is not confirmed.

Headscale has no OAuth client, so the pre-auth key takes the place of the OAuth
client in decision 6.

Action: read the official documents of the action and of Headscale. Record the
method here. Then test a job that reaches the Proxmox API.

### New risk: the port on the RackNerd VPS

Headscale needs a public name in DNS and a certificate for TLS. The RackNerd VPS
runs Pangolin, and Pangolin uses port 443. A conflict is possible.

Action: put Headscale behind the reverse proxy of Pangolin, or give Headscale
another port. Record the answer before task C2 in `docs/todo.md`.

## 5. The rights of the user for the provider — open

The provider uses SSH for some operations, and it can need sudo on the node.

Action: read the current documents of the provider. Create a dedicated user with
the exact rights that the documents give. Do not guess the rights. Record the
steps in a new runbook.

## 6. The panel of each VPS — closed for RackNerd, on hold for DediRock

The RackNerd VPS uses SolusVM. The name of the panel is NerdVM. The handoff was
correct for this host.

The DediRock VPS uses vPanel, and not WHMCS with Virtualizor. The handoff was
wrong for this host. The owner tests the host now, so no work goes to DediRock.
Ask the owner before you add DediRock to the inventory of Ansible.

## 7. The import of the resources that exist — open

No VM is in the OpenTofu state now. The plan tries to create a copy of each VM
if you do not import it first.

These workloads exist:

- A Talos cluster of three nodes, on `prometheus`.
- A TrueNAS VM, on `prometheus`.
- Home Assistant, on `atlas`.

Warning: `prometheus` gets a new install of Proxmox VE, and a new name, `gaia`.
A new install deletes the workloads on the host. Import a workload from `atlas`
first, and import a workload from the cluster after the new install is complete.

Action: run `qm list` and `pct list` on `atlas`. Record the identity number and
the name of each VM. Then write the import step for each one.

## 8. The new install on `prometheus` — new risk, open

The owner installs Proxmox VE again on `prometheus`, and gives the host the new
name `gaia`.

This risk changes the build order. Step 5 uses `pve-standalone`, which is
`atlas`, so step 5 is safe now. Step 6 uses `pve-cluster`, which holds
`prometheus`. Do not start step 6 before the new install is complete.

Action: ask the owner when `gaia` is ready. Then update
`docs/runbooks/inventory.md`.
