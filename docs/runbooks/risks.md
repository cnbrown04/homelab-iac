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

## 3. The version number of the provider — closed

OpenTofu 1.12.6 resolved `bpg/proxmox` version `0.114.0` on 26 September 2026.
Both target roots pin this version and commit a lock file.

Renovate can update the pin. Review the changelog for each provider update; see
risk 2.

## 4. The way a runner joins the network — method confirmed, test open

The owner replaced Tailscale with Headscale on 21 September 2026. Headscale is
an open-source control server. The client software of Tailscale stays the same,
but the control server is not the service of Tailscale.

The official action uses `tailscale/github-action@v4`. Its `authkey` input
accepts the pre-auth key, and its `args` input passes extra arguments to
`tailscale up`. Headscale documents `tailscale up --login-server <URL>
--authkey <KEY>` for this login method.

Set `args: --login-server=https://<Headscale DNS name>` and store the reusable,
ephemeral, tagged pre-auth key in the GitHub secret. Create the key with
`--reusable --ephemeral --tags tag:github-actions`. Headscale keys expire after
one hour by default. Choose a longer expiry that fits the key rotation plan
before task C6. Do not set the action's `tags` input; the Headscale key supplies
the tag.

The method is confirmed. Test a GitHub Actions job that reaches the Proxmox API
in task C7. The owner chose Tailscale's public DERP relays on 27 September 2026.

Sources:

- [Tailscale GitHub Action v4 inputs](https://github.com/tailscale/github-action/blob/v4/action.yml)
- [Headscale node registration](https://headscale.net/stable/ref/registration/)
- [Headscale pre-auth key flags](https://github.com/juanfont/headscale/blob/main/cmd/headscale/cli/preauthkeys.go)

### The public port on `hermes` — closed

Headscale needs a public DNS name and TLS. Pangolin uses port 443 on `hermes`.
Traefik in the Pangolin stack terminates TLS for `vpn.buildwithcaleb.com`, and
it sends the traffic to Headscale on a private address. Tailscale manages the
public DERP relay names; they do not use the Headscale domain.

See `docs/runbooks/hermes-edge.md`.

## 5. The rights of the user for the provider — documented

The provider needs API access for normal VM and container work. SSH is optional.
See `docs/runbooks/proxmox-user.md` for the SSH-backed features and documented
`sudo` rights. Add no SSH rights until a target uses one of those features.

## 6. The panel and use of `hermes` — panel facts closed, migration open

The owner confirmed that `hermes` uses vPanel and is hardened. The owner plans
to run the external services and Headscale on `hermes`. The owner chose
Tailscale's public DERP relays and Dockhand for Docker Compose stacks. The owner
accepts Dockhand's BSL 1.1 license for personal homelab use.
The license changes to Apache 2.0 on 1 January 2029. Inventory all services and
their data before migration.

Source: [Dockhand license](https://github.com/Finsys/dockhand/blob/main/LICENSE.txt)

## 7. Dockhand access — open

Dockhand can control Docker through the Docker socket. This access can give an
attacker control of the host. The first launch has authentication disabled.

Action: enable authentication before you expose the UI. Keep the UI private.
Assess a Docker socket proxy before setup.

## 8. The import of the resources that exist — open

No VM is in the OpenTofu state now. The plan tries to create a copy of each VM
if you do not import it first.

This workload remains:

- Home Assistant, on `atlas`.

The owner deleted the Talos cluster and TrueNAS VM. The owner reinstalled
`prometheus` as `gaia`; no workload is recorded on the `pantheon` cluster now.

The owner recorded VMID `100`, name `haos-18.2`, on `atlas`. The host has no
containers. Write and run the import step for VMID `100` before any apply.

## 9. The new install on `prometheus` — closed

The owner reinstalled Proxmox VE on `prometheus` and renamed it `gaia`. The owner
renamed `helios` to `theia`. The `pantheon` cluster now has `gaia`, `hyperion`,
`tartarus`, and `theia`.

The reinstall is complete. The owner confirmed the Proxmox versions on `gaia`
and `theia` on 26 September 2026.

## 10. Recovery of remote state — closed

The owner selected Cloudflare R2 for remote state. OpenTofu can use R2's S3 API
and conditional writes for state locks. R2 does not provide object versioning.
The owner confirmed that both roots initialized against R2, and that a separate
versioned backup and restore test are complete.

Keep the tested backup process active. Do not rely on R2 for object versioning.
