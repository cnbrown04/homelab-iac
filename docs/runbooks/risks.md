# The risks, and the answer to each one

Step 1 of the build order says: verify each risk, then record the answer. This
document holds the answers. The risks come from `context/handoff-original.md`.

Git ignores `context/`, but git keeps this document. This document is the record
that lasts.

## 1. The version of Proxmox VE — closed

The five nodes reported `pve-manager/9.2.20` and kernel `7.0.14-17-pve` on
21 September 2026. On 26 September, `gaia` and `theia` reported
`pve-manager/9.2.20` and kernel `7.0.14-19-pve` after the reinstall and rename.

Every node runs the 9.x line in the latest recorded check. The bpg provider
supports 9.x in full. See `docs/runbooks/inventory.md` for the check dates.

Caution: the kernel number is not the version of Proxmox VE. Read `pve-manager`
only.

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

## 6. The panel and use of each VPS — panel facts closed, DediRock plan open

The RackNerd VPS uses SolusVM. The name of the panel is NerdVM. The handoff was
correct for this host.

The DediRock VPS uses vPanel, and not WHMCS with Virtualizor. The handoff was
wrong for this host. The owner plans to use it for services outside the homelab.
The owner says the host still needs hardening. Dockage is preferred, but the
service manager is not chosen. Harden the host before service setup. Confirm the
needed ports before you turn on UFW.

## 7. The import of the resources that exist — open

No VM is in the OpenTofu state now. The plan tries to create a copy of each VM
if you do not import it first.

This workload remains:

- Home Assistant, on `atlas`.

The owner deleted the Talos cluster and TrueNAS VM. The owner reinstalled
`prometheus` as `gaia`; no workload is recorded on the cluster now.

The owner recorded VMID `100`, name `haos-18.2`, on `atlas`. The host has no
containers. Write and run the import step for VMID `100` before any apply.

## 8. The new install on `prometheus` — closed

The owner reinstalled Proxmox VE on `prometheus` and renamed it `gaia`. The owner
renamed `helios` to `theia`. The cluster now has `gaia`, `hyperion`, `tartarus`,
and `theia`.

The reinstall is complete. The owner confirmed the Proxmox versions on `gaia`
and `theia` on 26 September 2026.
