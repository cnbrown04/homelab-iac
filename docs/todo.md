# The list of tasks

This list holds the open work, in order. Mark a task complete when the evidence
goes into a runbook. `AGENTS.md` holds the build order, and this list holds the
detail of each step.

## A. Close the open risks

See `docs/runbooks/risks.md` for the full text of each risk.

- [x] **A1. Get the version of the provider.** OpenTofu resolved `bpg/proxmox`
      `0.114.0`; both roots pin it and have lock files.
- [x] **A2. Get the rights of the user for the provider.** Record the documented
      API and SSH requirements in `docs/runbooks/proxmox-user.md`.
- [x] **A3. List the resources on `atlas`.** The owner recorded VMID `100`,
      `haos-18.2`, and no containers in `docs/runbooks/inventory.md`.
- [x] **A4. Find how a runner joins a Headscale network.** Record the method in
      risk 4. Test it in task C7.
- [x] **A5. Confirm that `gaia` is ready.** The owner confirmed the reinstall
      and the new cluster membership on 26 September 2026.
- [x] **A6. Check Proxmox versions on `gaia` and `theia`.** The owner recorded
      `pve-manager/9.2.20` and kernel `7.0.14-19-pve` in the inventory.

## B. Scaffold the repository — build order step 2

- [x] **B1. Create the layout.** Add the OpenTofu roots, modules, Ansible
      folders, and GitHub Actions folder.
- [x] **B2. Add `renovate.json`.** Enable updates for mise, OpenTofu providers,
      Ansible collections, and GitHub Actions.
- [x] **B3. Add `ansible/requirements.yml`.** Pin `community.proxmox` to `1.6.0`.
- [x] **B4. Correct the old comments.** Point the comments in `mise.toml` and
      `.gitignore` to `AGENTS.md`.

## C. Set up Ansible and Headscale — build order step 4

The owner replaced Tailscale with Headscale on 21 September 2026. Headscale is
an open-source control server. The client software of Tailscale stays the same.

Warning: Headscale must run out of the homelab. See decision 3 in `AGENTS.md`.
The `hermes` host runs Headscale and the external services. Headscale uses
Tailscale's public DERP relays.

- [x] **C0. Choose the Compose manager.** The owner chose Dockhand and
      accepted its BSL 1.1 license for personal homelab use on 27 September 2026.
- [ ] **C0.1. List all workloads to move.** Record each service, its data,
      configuration, ports, DNS names, and backup needs before setup.
- [ ] **C0.2. Protect the Dockhand interface.** Enable authentication before
      Pangolin exposes the UI. Keep the UI private, and assess a Docker socket
      proxy before setup.
- [x] **C1. Choose the Headscale DNS name and route.** Traefik in the Pangolin
      stack sends `vpn.buildwithcaleb.com` to Headscale. See
      `docs/runbooks/hermes-edge.md`.
- [x] **C1.1. Deploy Pangolin.** The owner deployed Pangolin and created the
      admin account on 27 September 2026. The dashboard has a valid
      Let's Encrypt certificate.
- [x] **C2. Deploy Headscale.** Ansible installed Headscale 0.29.3 on
      27 September 2026. `https://vpn.buildwithcaleb.com/health` returned
      `200`, and the certificate is valid.
- [x] **C3. Set the policy.** `tag:github-actions` gets TCP port `8006` on
      `tag:proxmox` only. The devices of the owner (`autogroup:member`) get
      all nodes and all ports. The owner chose this on 27 September 2026, and
      plans to make the policy narrow later.
- [x] **C4. Choose the relay.** The owner chose Tailscale's public DERP relays
      on 27 September 2026.
- [x] **C5. Join each Proxmox node.** The `tailscale` role joined the five
      nodes with `tag:proxmox` on 27 September 2026. A second run showed no
      change. `docs/runbooks/inventory.md` holds the tailnet addresses.
- [x] **C6. Create the pre-auth key for the pipeline.** The key is reusable
      and ephemeral, and it has the tag `tag:github-actions`. It is in the
      GitHub secret `HEADSCALE_AUTHKEY`. Warning: the key expires on
      26 December 2026. Make a new key and replace the secret before that date.
- [x] **C7. Test the join from a runner.** Run 36350927486 of
      `.github/workflows/tailnet-check.yml` passed on 27 September 2026. Each
      node returned HTTP `200` on port `8006`, and the policy blocked port `22`.
- [ ] **C8. Install the Headplane admin interface.** The `headplane` role
      runs Headplane 0.7.1 in Docker at `https://vpn.buildwithcaleb.com/admin`.
      It mounts the Headscale configuration read-only, because Ansible owns
      that file. The owner chose this on 27 September 2026. Change the
      Headscale configuration and policy in the repository, not in the UI.

## E. Bootstrap `hermes`

- [x] **E1. Write the hardening script.** `scripts/vps-harden.sh` protects a new
      VPS. It uses whiptail, the text interface of Debian and Ubuntu.
- [x] **E2. Write the runbook.** `docs/runbooks/hermes-bootstrap.md`.
- [x] **E3. Confirm the `hermes` hardening.** The owner confirmed setup.
- [ ] **E4. Make an Ansible role from the script.** Ansible owns `hermes` after
      the bootstrap. The role keeps the same configuration.

## D. The rest of the build order

- [x] **D1. Step 3.** Set up the remote state backend, the state encryption, and
      SOPS with age. The owner confirmed that both roots connect to R2 and that
      the separate backup and restore test are complete. `.sops.yaml` has the
      age recipient. The local encrypt/decrypt test passed, and the owner added
      the private key as a GitHub secret.
- [ ] **D2. Step 5.** Write the `vm` module and the `lxc` module. Write the
      `atlas` target. Import Home Assistant.
- [ ] **D3. Step 6.** Do step 5 again for the `pantheon` cluster. See the current
      versions in `docs/runbooks/inventory.md`.
- [ ] **D4. Step 7.** Write the Ansible baseline for the five Proxmox nodes and
      `hermes`.
- [ ] **D5. Step 8.** Add the workflows with a matrix over the targets.
