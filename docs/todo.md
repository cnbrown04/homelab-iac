# The list of tasks

This list holds the open work, in order. Mark a task complete when the evidence
goes into a runbook. `AGENTS.md` holds the build order, and this list holds the
detail of each step.

## A. Close the open risks

See `docs/runbooks/risks.md` for the full text of each risk.

- [ ] **A1. Get the version of the provider.** Run `tofu init` in a target, then
      read `.terraform.lock.hcl`. Write the version into risk 3. Needs task B1.
- [ ] **A2. Get the rights of the user for the provider.** Read the current
      documents of the provider. Write the exact rights into a new runbook,
      `docs/runbooks/proxmox-user.md`. Do not guess a right.
- [ ] **A3. List the resources on `atlas`.** Run `qm list` and `pct list` on the
      host. Record each identity number and each name in
      `docs/runbooks/inventory.md`. **The owner does this task.**
- [ ] **A4. Find how a runner joins a Headscale network.** This task replaces
      the old risk 4. See section C.
- [ ] **A5. Ask when `gaia` is ready.** The new install on `prometheus` blocks
      step 6. **The owner does this task.**

## B. Scaffold the repository — build order step 2

- [ ] **B1. Create the layout.** Create `tofu/modules/`, `tofu/targets/`,
      `ansible/`, and `.github/workflows/`. See `AGENTS.md` for the full tree.
- [ ] **B2. Add `renovate.json`.** Renovate bumps `mise.toml`, the provider, and
      the actions of GitHub.
- [ ] **B3. Add `ansible/requirements.yml`.** Pin the `community.proxmox`
      collection.
- [ ] **B4. Correct the old comments.** `mise.toml` and `.gitignore` name
      "CLAUDE.md, decision 1", but no `CLAUDE.md` exists. The decisions are in
      `AGENTS.md`, section 3.

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
      ephemeral node with the tag for GitHub Actions. Put the key in a GitHub
      secret.
- [ ] **C7. Test the join from a runner.** A job must reach the Proxmox API.
      Task A4 gives the method.

## E. The bootstrap of a VPS — complete

- [x] **E1. Write the hardening script.** `scripts/vps-harden.sh` protects a new
      VPS. It uses whiptail, the text interface of Debian and Ubuntu.
- [x] **E2. Write the runbook.** `docs/runbooks/vps-bootstrap.md`.
- [ ] **E3. Run the script on the RackNerd VPS.** The host runs CrowdSec,
      Fail2ban, and Pangolin now. Caution: select only the tasks that the host
      does not have. **The owner does this task.**
- [ ] **E4. Make an Ansible role from the script.** Ansible owns the host after
      the bootstrap. The role keeps the same configuration.

## D. The rest of the build order

- [ ] **D1. Step 3.** Set up the remote state backend, the state encryption, and
      SOPS with age.
- [ ] **D2. Step 5.** Write the `vm` module and the `lxc` module. Write the
      `pve-standalone` target for `atlas`. Import Home Assistant.
- [ ] **D3. Step 6.** Do step 5 again for the `pantheon` cluster. Warning: wait
      for `gaia`. See task A5.
- [ ] **D4. Step 7.** Write the Ansible baseline for the five Proxmox nodes and
      the two VPS hosts.
- [ ] **D5. Step 8.** Add the workflows with a matrix over the targets.
