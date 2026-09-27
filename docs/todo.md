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

## C. Set up Headscale — build order step 4

The owner replaced Tailscale with Headscale on 21 September 2026. Headscale is
an open-source control server. The client software of Tailscale stays the same.

Warning: Headscale must run out of the homelab. See decision 3 in `AGENTS.md`.
The RackNerd VPS is the correct host, because it is public and it does not need
the homelab.

- [ ] **C1. Choose the name in DNS and the port.** Caution: the RackNerd VPS
      runs Pangolin, and Pangolin uses port 443. Headscale needs TLS on a public
      port. Put Headscale behind the reverse proxy of Pangolin, or give it
      another port. Record the answer in a new runbook.
- [ ] **C2. Write the Ansible role for Headscale.** The role installs the
      server, writes the configuration, and starts the service. Do not install
      it by hand.
- [ ] **C3. Set the policy.** Headscale uses an access control list. Give the
      tag for GitHub Actions access to the Proxmox API port only.
- [ ] **C4. Choose the relay.** Headscale uses the public relays of Tailscale by
      default. Decide if that is acceptable, or run a relay on the VPS.
- [ ] **C5. Join each Proxmox node.** The five nodes and both VPS hosts join the
      mesh network. Use a pre-auth key with a tag.
- [ ] **C6. Create the pre-auth key for the pipeline.** The key makes an
      ephemeral node with the tag for GitHub Actions. Choose the key expiry;
      Headscale defaults to one hour. Put the key in a GitHub secret.
- [ ] **C7. Test the join from a runner.** A job must reach the Proxmox API.
      Task A4 gives the method.

## E. The bootstrap of a VPS — complete

- [x] **E1. Write the hardening script.** `scripts/vps-harden.sh` protects a new
      VPS. It uses whiptail, the text interface of Debian and Ubuntu.
- [x] **E2. Write the runbook.** `docs/runbooks/vps-bootstrap.md`.
- [x] **E3. Confirm the RackNerd VPS hardening.** The owner says the host is
      already hardened. Do not run `scripts/vps-harden.sh` on it again.
- [ ] **E4. Make an Ansible role from the script.** Ansible owns the host after
      the bootstrap. The role keeps the same configuration.
- [x] **E5. Harden the DediRock VPS.** The owner confirmed setup on 26 September
      2026. Do not run the script on RackNerd again.

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
      the two VPS hosts.
- [ ] **D5. Step 8.** Add the workflows with a matrix over the targets.
- [ ] **D6. Assess a service manager for DediRock.** The owner prefers Dockage or
      a similar tool for services outside the homelab. Confirm host readiness
      and choose the tool before setup.
