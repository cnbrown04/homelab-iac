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

- [x] **C0. Choose the Compose manager.** The owner chose Dockhand, then
      changed to Dockge on 27 September 2026. Dockge has the MIT license.
- [ ] **C0.1. List all workloads to move.** Record each service, its data,
      configuration, ports, DNS names, and backup needs before setup.
- [x] **C0.2. Protect the Dockge interface.** The Pangolin login protects
      `dockge.buildwithcaleb.com`. The owner made the Dockge admin account on
      27 September 2026. See risk 7.
- [x] **C1. Choose the Headscale DNS name and route.** Traefik in the Pangolin
      stack sends `vpn.buildwithcaleb.com` to Headscale. See
      `docs/runbooks/hermes-edge.md`.
- [x] **C1.1. Deploy Pangolin.** The owner deployed Pangolin and created the
      admin account on 27 September 2026. The dashboard has a valid
      Let's Encrypt certificate.
- [x] **C1.2. Change Pangolin to the Enterprise Edition.** The image is
      `fosrl/pangolin:ee-<version>`. The owner activated the free license key
      for personal use on 27 September 2026.
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
      GitHub secret `HEADSCALE_AUTHKEY`. On 27 September 2026 the owner
      replaced the first key (90 days) with a key of 3650 days. See task F3.
- [x] **C7. Test the join from a runner.** Run 36350927486 of
      `.github/workflows/tailnet-check.yml` passed on 27 September 2026. Each
      node returned HTTP `200` on port `8006`, and the policy blocked port `22`.
- [x] **C8. Install the Headplane admin interface.** The `headplane` role
      runs Headplane 0.7.1 in Docker. A Pangolin blueprint publishes it at
      `https://headplane.buildwithcaleb.com` with the Pangolin login. It mounts
      the Headscale configuration read-only, because Ansible owns that file.
      Headscale keeps its file route. See `docs/runbooks/hermes-edge.md`. The
      owner confirmed the login on 27 September 2026.
- [x] **C9. Turn on MagicDNS.** The owner chose the base domain
      `vnet.buildwithcaleb.com` on 27 September 2026. Headscale refuses
      `vpn.buildwithcaleb.com`, because that is the host name of the server.
      The Proxmox nodes keep `--accept-dns=false`. A local test with
      Headscale 0.29.3 passed `configtest`. On 27 September 2026 the desktop
      of the owner reached `gaia.vnet.buildwithcaleb.com`.
- [x] **C10. Log in personal devices with Pocket ID.** Headscale uses Pocket
      ID through OIDC, with PKCE. Headscale starts when Pocket ID is down. A
      local test with Headscale 0.29.3 and an issuer that did not answer
      showed that Headscale started and `/health` returned `200`. On
      27 September 2026 the desktop of the owner joined as the OIDC user, and
      the owner deleted the local user `caleb`. Headplane and Headscale share
      the Pocket ID client `VPN`. See `docs/runbooks/hermes-edge.md`.

## E. Bootstrap `hermes`

- [x] **E1. Write the hardening script.** `scripts/vps-harden.sh` protects a new
      VPS. It uses whiptail, the text interface of Debian and Ubuntu.
- [x] **E2. Write the runbook.** `docs/runbooks/hermes-bootstrap.md`.
- [x] **E3. Confirm the `hermes` hardening.** The owner confirmed setup.
- [ ] **E4. Make an Ansible role from the script.** Ansible owns `hermes` after
      the bootstrap. The role keeps the same configuration. It manages the
      admin user and key, the SSH settings in
      `/etc/ssh/sshd_config.d/99-hardening.conf`, the UFW rules, the
      configuration of Fail2ban and CrowdSec, the sysctl values, and
      `unattended-upgrades`. Now the roles only check that Fail2ban and
      CrowdSec are installed. Warning: test the SSH change with a second
      session open, as in `docs/runbooks/hermes-bootstrap.md`.

## F. Operate `hermes`

Do these tasks in order. The owner chose to do the backups late. Warning:
`hermes` has no backup until task F6 is complete. Do task F6 before the
upgrade to Headscale 0.30.

- [x] **F1. Deploy Pocket ID.** The owner chose Pocket ID as the SSO provider
      on 27 September 2026. Pocket ID 2.16.0 has the BSD-2-Clause license. It
      uses passkeys only. The `pocket_id` role deploys it in Docker on
      `hermes`, at `auth.buildwithcaleb.com`. It is always a Pangolin resource,
      as the owner chose. The Pangolin login protects it during the setup of
      the first admin. See `docs/runbooks/hermes-edge.md`. The owner made the
      admin account on 27 September 2026.
- [x] **F2. Give Headplane a login that does not expire.** Headplane does not
      renew its Headscale API key, and each API key has an expiry. Do these
      steps:
      - Log in to Headplane with Pocket ID through OIDC, with PKCE (`S256`).
        The redirect URL is
        `https://headplane.buildwithcaleb.com/admin/oidc/callback`.
      - Ansible makes the Headscale API key for Headplane on `hermes`, with an
        expiry of 3650 days. It writes the key to a file, and Headplane reads
        the file through `headscale.api_key_path`. The key does not go into the
        repository or into SOPS.
      - On each run, Ansible makes a new key when the old key has less than
        365 days left. Then it restarts Headplane and expires the old key.
      The key stays on `hermes`, and Headscale runs as root there, so a long
      expiry adds almost no risk. A test on 27 September 2026 showed that
      Headscale 0.29.3 accepts an API key of 3650 days. The `headplane` role
      does these steps. A test against Headscale 0.29.3 passed: a new key, no
      change on the next run, and a renewal of a key with 100 days left.
      On 27 September 2026 the owner logged in to Headplane with Pocket ID.
- [ ] **F3. Give the pipeline a login that does not expire.**
      - Done on 27 September 2026: the key in `HEADSCALE_AUTHKEY` is a
        reusable, ephemeral key with `tag:github-actions`. It is key ID 3, and
        it expires on 24 September 2036. The owner expired the old key (ID 2).
        Run 36356366413 of `tailnet-check.yml` passed. Run 36356487526 passed
        after the old key expired, so the secret holds the new key.
        `docs/runbooks/pipeline-tailnet-key.md` holds the steps.
      - After the upgrade to Headscale 0.30: use an OAuth client. Run
        `headscale oauth-clients create --scope auth_keys --tag
        tag:github-actions`. An OAuth client has no expiry. Store
        `tskey-client-<id>-<secret>?baseURL=https://vpn.buildwithcaleb.com` in
        `HEADSCALE_AUTHKEY`, and add `--advertise-tags=tag:github-actions` to
        the `args` of the action. Keep the `authkey` input, because
        `oauth-secret` breaks `baseURL`. Each job then gets a new single-use
        key. Delete the pre-auth key.
      - Warning: Headscale 0.30 moves all keys into one new table, and the
        migration cannot be reversed. Do task F6 before the upgrade. Do not
        merge a Renovate pull request for 0.30 without a backup.
      Source: the 0.30.0 section of the Headscale changelog, and
      `docs/ref/api.md` on the `main` branch.
- [ ] **F4. Install the Renovate app.** `renovate.json` exists, but the
      Renovate app is not installed on the repository. On 27 September 2026
      the repository had no Dependency Dashboard issue and no Renovate pull
      request. Install the app, and merge the onboarding pull request.
      Headscale 0.29.4 is the first expected update.
- [x] **F5. Check `hermes` with no change.** Run
      `ansible-playbook playbooks/site.yml --check --diff --limit hermes -K`.
      Correct each task that shows a change. This is the `hermes` part of
      task D4.
      On 27 September 2026 the check showed `ok=88 changed=0 failed=0`. The
      read-only command tasks run in check mode, and the Headscale package
      installs only on a version change.
- [ ] **F6. Back up `hermes`.** Nothing backs up `hermes` now. Write an Ansible
      role that runs restic on a systemd timer, and sends encrypted backups to
      R2. Keep the restic password in SOPS. Back up these paths:
      - `/var/lib/headscale`: the database and the noise private key. Without
        them, each node and device must join again.
      - `/etc/headscale`: the configuration and the policy. The repository
        also holds them.
      - `/opt/stacks/pangolin/config`: the Pangolin database, the license,
        the Gerbil key, and the Let's Encrypt certificates.
      - `/opt/stacks/headplane/data` and `/opt/dockge/data`.
      - `/opt/stacks/pocket-id/data`: the users and passkeys. The key in
        `pocket_id_encryption_key` must be available for a restore.
      Write a restore test in a runbook, and do the test one time.
- [x] **F7. Deploy `hermes` from the pipeline.** The workflow
      `.github/workflows/ansible-hermes.yml` runs a check on each pull
      request, and an apply after a merge to `main`. The apply waits for the
      approval of the owner. The runner logs in as `iac-admin` with its own
      key. Do the one-time setup in `docs/runbooks/pipeline-hermes.md`. This is
      the `hermes` part of task D5. The Proxmox nodes are not in the pipeline,
      because `tag:github-actions` gets port `8006` only. On 28 September 2026
      pull request 4 passed the check job (run 36361354941). After the merge,
      the apply job (run 36361957940) showed `changed=0` in the apply and in
      the check after it.

C0.1 is also open for `hermes`: list the workloads on the old VPS before
their move.

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
