# Agent rules for this repository

These rules apply to every agent and every person who writes content here.

## 1. Write in Simplified Technical English

Write all chat replies, code comments, documents, and commit messages in
ASD-STE100 Simplified Technical English. See https://www.asd-ste100.org/.

The standard has two parts: a dictionary of approved words, and 53 writing
rules. Use the rules below. They are the part of the standard that changes
the text most.

### Words

- Use one word for one meaning. Do not use a synonym later in the same
  document. If you write "delete", do not change to "remove".
- Use one part of speech for one word. "Test" is a noun or a verb, but keep
  to one use in one document.
- Use the approved word when a simple word exists: "start" and not
  "initiate", "use" and not "utilize", "before" and not "prior to".
- Keep technical names and technical verbs. "OpenTofu", "SOPS", "encrypt",
  and "provision" are correct.
- Do not use more than three nouns together. Write "the token for the API of
  Proxmox" and not "the Proxmox API token cluster".

### Sentences

- Write one instruction in one sentence.
- Keep an instruction to 20 words or less. Keep a description to 25 words
  or less.
- Use the active voice. Write "OpenTofu creates the VM" and not "the VM is
  created by OpenTofu".
- Use the imperative for an instruction. Write "Run `mise install`."
- Use the simple present or the simple past tense. Do not use the future
  tense and do not use the perfect tense.
- Do not use a verb that ends in "-ing" as the main verb.
- Keep the articles "a", "an", and "the". Do not delete them to make the
  text short.
- Write a paragraph of six sentences or less.

### Warnings and cautions

Put the warning before the instruction. Give the condition first, then the
action.

### Exceptions

These rules do not apply to:

- Command names, file paths, flags, and code.
- Output that you copy from a tool.
- Text that you quote from a third party.

## 2. Use Conventional Commits

Write every commit message in the Conventional Commits format. See
https://www.conventionalcommits.org/.

```
<type>(<scope>): <description>
```

### Types

| Type | Use |
| --- | --- |
| `feat` | A new capability. |
| `fix` | A correction of a defect. |
| `docs` | A change to documents only. |
| `refactor` | A change that does not add a capability or correct a defect. |
| `test` | A change to tests only. |
| `ci` | A change to the GitHub Actions workflows. |
| `build` | A change to the toolchain, for example `mise.toml`. |
| `chore` | Other work, for example a version bump. |

### Scopes

Use the area of the repository as the scope: `tofu`, `ansible`, `mise`,
`ci`, `docs`, `secrets`. Use no scope if the change touches many areas.

### Rules

- Write the description in the imperative. Write "add the node" and not
  "added the node" or "adds the node".
- Start the description with a lower case letter. Do not put a full stop at
  the end.
- Keep the first line to 72 characters or less.
- Write the first line only. A commit message has no body. Put the reason for
  the change in the pull request.
- Mark a breaking change with a `!` after the type. A footer is the one
  exception to the rule above.

### Branches

Name a branch `<type>/<short-description>`, for example
`feat/proxmox-vm-module`. Use the same type names as the commits.

## 3. Ask before you write to git

Do not run `git commit`, `git push`, or `gh pr create` unless the owner gives
permission for that action.

- Make the change to the file, then stop. Tell the owner what is ready.
- Permission for one commit is not permission for the next commit.
- This rule covers a new branch on the remote, a push, and a pull request.
- `git add`, `git status`, and `git diff` need no permission.

## 4. Project context

This repository manages a homelab. OpenTofu manages the Proxmox guests.
Ansible manages the hosts. The pipelines apply each change after the owner
approves it. The owner pushes to `main` directly for now.

### The hosts

Always refer to a machine by its hostname, not by its provider.

| Host | Role | LAN | Tailnet |
| --- | --- | --- | --- |
| `atlas` | Proxmox VE, standalone. Runs Home Assistant (VMID `100`). | `10.0.1.124` | `100.64.0.3` |
| `gaia` | Proxmox VE, cluster `pantheon` | `10.0.1.120` | `100.64.0.5` |
| `hyperion` | Proxmox VE, cluster `pantheon` | `10.0.1.101` | `100.64.0.2` |
| `tartarus` | Proxmox VE, cluster `pantheon` | `10.0.1.113` | `100.64.0.4` |
| `theia` | Proxmox VE, cluster `pantheon` | `10.0.1.131` | `100.64.0.1` |
| `hermes` | Public VPS, Ubuntu 24.04. The owner has a noVNC console in vPanel. | `192.255.220.7` (public) | none |

Proxmox VE is 9.2 on Debian trixie. The `pantheon` cluster runs the Talos
Kubernetes cluster `typhon`.
The web UI of each node is at `https://<host>.vnet.buildwithcaleb.com`, with a
Let's Encrypt certificate and the Pocket ID login (realm `pocketid`).
Ansible logs in to each host as `iac-admin`, with sudo and a password. The
password is the same on each host.

### The `typhon` cluster

Talos v1.14 and Kubernetes 1.36, on VLAN 20 (`10.0.20.0/24`). The API is at
the VIP `https://10.0.20.10:6443`. OpenTofu makes the VMs. talhelper makes the
Talos config. Flux deploys the rest from `main`, with a read-only deploy key.
A SOPS file in `typhon-cluster/` has two keys: the owner key and the key of
the cluster.

| VM | VMID | Node | IP |
| --- | --- | --- | --- |
| `typhon-cp-1` | `501` | `gaia` | `10.0.20.11` |
| `typhon-w-1` | `511` | `gaia` | `10.0.20.21` |
| `typhon-w-2` | `512` | `gaia` | `10.0.20.22` |
| `typhon-w-3` | `513` | `hyperion` | `10.0.20.23`, with the iGPU of `hyperion` |
| `typhon-w-4` | `514` | `hyperion` | `10.0.20.24` |

- The cluster has one control plane. `gaia` holds the NFS storage, so `gaia`
  is a single point of failure already.
- `gaia` has `10.0.20.5` on VLAN 20. It exports `/lethe/k8s` and
  `/lethe/data/media` to VLAN 20 only. It routes VLAN 20 for the tailnet.
- The Cilium LoadBalancer pool is `10.0.20.200` to `10.0.20.249`. The UniFi
  DHCP range is `10.0.20.100` to `10.0.20.199`.
- A Talos worker has 8 GiB of RAM or less. The data of an app goes to NFS,
  and SQLite goes to `local-path`.
- The files of a cluster go in `<name>-cluster/`.
- The Pangolin site `typhon` (identifier `typhon-cluster`) is a basic
  WireGuard site, not Newt. Newt runs
  WireGuard in userspace, and it gave about 40 Mbit/s. Gerbil and the pod
  `pangolin-wireguard` both use kernel WireGuard. The pod has the tunnel
  address `100.89.128.4`, and it sends TCP port 80 to the Gateway
  `10.0.20.200`. Gerbil does not answer a ping through the tunnel.
- To add an app to `typhon`: put it in `typhon-cluster/apps/<name>/`, with an
  HTTPRoute to the Gateway `main` in the namespace `gateway`. Add a resource to
  `pangolin_blueprint_resources`. Its target uses the site
  `{{ pangolin_typhon_site }}`, the hostname `{{ pangolin_typhon_target }}`,
  and the port `80`.

### The services on `hermes`

`*.buildwithcaleb.com` has a wildcard DNS record to `hermes`.

| Name | Service | Route |
| --- | --- | --- |
| `vpn.buildwithcaleb.com` | Headscale 0.29.4, a system service on `10.200.0.1:8085` | Traefik file route |
| `pangolin.buildwithcaleb.com` | Pangolin Enterprise Edition, with Traefik and Gerbil | Traefik file route |
| `auth.buildwithcaleb.com` | Pocket ID, the SSO provider | Pangolin resource, no Pangolin login |
| `headplane.buildwithcaleb.com` | Headplane | Pangolin resource, Pangolin login |
| `dockge.buildwithcaleb.com` | Dockge | Pangolin resource, Pangolin login |

- The Docker network `pangolin` has the subnet `10.200.0.0/24`. Headscale
  listens on its gateway. A UFW rule lets the network reach it.
- MagicDNS gives each node `<host>.vnet.buildwithcaleb.com`. Personal devices
  log in to Headscale with Pocket ID. Headscale and Headplane share the Pocket
  ID client `VPN`.
- `pangolin_blueprint_resources` in `host_vars/hermes/main.yml` defines the
  Pangolin resources. The `pangolin_blueprint` role sends it to the
  integration API of Pangolin.
- restic backs up the data of `hermes` each day at 03:30, to the R2 bucket
  `homelab-hermes-backup`. `/etc/restic/backup.env` holds the settings. Start
  a backup with `sudo systemctl start backup.service`.

### Decisions

These decisions are closed. Ask the owner before you re-open one.

1. **Use OpenTofu, not Terraform.**
2. **Each tool does one job.** OpenTofu manages Proxmox guests. Ansible
   configures hosts. Do not create a VM with Ansible. Do not manage a VPS with
   OpenTofu.
3. **Use GitHub-hosted runners only.** A job joins the tailnet as an ephemeral
   node with `tag:github-actions`. Headscale is the control server, on
   `hermes`, out of the homelab. Use the public DERP relays of Tailscale.
4. **Headscale must not depend on the Pangolin app.** A Pangolin resource sends
   each request through the badger middleware, which fails when the Pangolin
   app is down. So Headscale keeps its Traefik file route.
5. **Pocket ID is always a Pangolin resource.** Pangolin keeps its local login,
   so the owner can log in when Pocket ID is down.
6. **The state is remote and encrypted,** in R2, with OpenTofu state
   encryption.
7. **SOPS and age encrypt the secrets.**
8. **A human approves each apply,** through a GitHub environment.
9. **The policy of the tailnet:** `tag:github-actions` gets TCP `8006` on
   `tag:proxmox` only. Personal devices get each node and port.
10. **The baseline of a Proxmox node:** SSH with keys only (root keeps key
    login, for the cluster), the kernel settings of `sysctl_hardening`, and
    automatic Debian security updates only. No Fail2ban, CrowdSec, or UFW.
    The `proxmox_web` role adds the web certificate, port 443, and SSO.
11. **Dockge is the Compose manager.** Ansible deploys each stack. Dockge does
    not.
12. **The Proxmox web UI:** an nftables rule sends port 443 to 8006. ACME uses
    the Cloudflare DNS-01 challenge, with the account `caleb@auburn.edu`.
    Members of the Pocket ID group `proxmox-admins` get the role
    Administrator. `pocketid` is the default realm on the login page.
    `root@pam` stays as the fallback login. Run the role by hand: no pipeline
    reaches the nodes.

### The repository

```text
tofu/modules/{vm,lxc}/      # one guest each
tofu/targets/{atlas,pantheon}/  # one root and one state each; guests are data in vms.tf and containers.tf
ansible/inventory/          # hosts.yml, group_vars/{all,proxmox_nodes}, host_vars/hermes
ansible/playbooks/          # site, hermes, headscale, pangolin_resources, stacks, proxmox_nodes, proxmox_bootstrap
ansible/roles/              # one job each
ansible/stacks/             # Compose files
secrets/tofu.sops.yaml      # R2 keys, state passphrase, Proxmox API tokens
scripts/tofu-env.sh         # exports the OpenTofu secrets of one target
scripts/vps-harden.sh       # the first bootstrap of a new VPS
.github/workflows/          # ansible-hermes, tofu, tofu-target, tailnet-check
typhon-cluster/talos/       # talconfig.yaml, talsecret.sops.yaml; clusterconfig/ is ignored
typhon-cluster/flux/        # the entry point of Flux; the order of the Kustomizations
typhon-cluster/infrastructure/{controllers,configs}/  # the base services, for Flux
typhon-cluster/apps/        # one folder for each app
```

To add a guest, add one entry to `vms.tf` or `containers.tf`. Do not write a
new resource block.

To add a service on `hermes`: put its Compose file in `ansible/stacks/<name>/`,
add `<name>` to `hermes_compose_stacks`, join the network `pangolin`, publish
no port, and add a resource to `pangolin_blueprint_resources`.

To add a host: a new VPS runs `scripts/vps-harden.sh`, then the play with
`-e ansible_user=caleb` one time. A new Proxmox node runs
`playbooks/proxmox_bootstrap.yml` as root, then `playbooks/proxmox_nodes.yml`.
Add the node to `hosts.yml` first, and to the group `pantheon` for the
cluster.

`mise.toml` holds each tool version. Renovate bumps the versions. Do not
change a version by hand.

### Working with the owner

- The agent has no sudo password. For a run with `-K` or a command as root,
  give the owner the exact command, and ask for the output.
- Give numbered steps with complete commands. After a change of plan, give the
  complete list of steps again.
- Write each command for the owner to run from the root of the repository.
  Do not use `cd`.
- The owner pushes to `main` directly. Each push to `ansible/` or `tofu/`
  starts a pipeline that waits for the approval of the owner.

### Commands

```sh
# Ansible. mise sets ANSIBLE_CONFIG to ansible/ansible.cfg.
ansible-playbook ansible/playbooks/hermes.yml --check --diff -K
ansible-playbook ansible/playbooks/proxmox_nodes.yml --check --diff -K

# OpenTofu
source scripts/tofu-env.sh atlas
tofu -chdir=tofu/targets/atlas plan
```

### The pipelines

- `ansible-hermes.yml`: lint, then a check with `--diff`. On a push to
  `main`, an apply follows only when the check shows a change. It waits for
  approval in the environment `hermes`. Then a second check must show no
  change. A run by hand with `force` applies also with no change, because a
  check does not run `command` tasks.
- `tofu.yml`: lint, then a plan of each target. On a push to `main`, a plan
  with changes waits for approval in the environment `atlas` or `pantheon`.
  Then the job applies the saved plan, and a new plan must show no change. A
  plan with no change needs no approval.
- After a failed apply, start a new run. The saved plan is stale.
- The `typhon` cluster is not in a pipeline, for the same reason. Run
  talhelper and talosctl by hand. Flux in the cluster pulls from GitHub.
- The Proxmox nodes are not in a pipeline, because the tailnet policy blocks
  SSH. Run their playbook by hand. The owner chose this on 28 September 2026.
  Do not open SSH to `tag:proxmox` for a pipeline. OpenTofu still deploys the
  guests through the API.

### Secrets

- SOPS files:

  | File | Content |
  | --- | --- |
  | `secrets/tofu.sops.yaml` | R2 keys, state passphrase, Proxmox API tokens |
  | `ansible/inventory/group_vars/all/secrets.sops.yml` | The password hash of `iac-admin` |
  | `ansible/inventory/group_vars/proxmox_nodes/secrets.sops.yml` | The Cloudflare DNS token, the Proxmox OIDC client |
  | `ansible/inventory/host_vars/hermes/secrets.sops.yml` | The secrets of the services on `hermes`, the backup keys |
  | `secrets/typhon-age-key.sops.yaml` | The private age key of `typhon`. Flux uses it as the secret `sops-age`. |
  | `typhon-cluster/talos/talsecret.sops.yaml` | The secrets of Talos. The owner key only. |

- GitHub secrets: `SOPS_AGE_KEY`, `HEADSCALE_AUTHKEY`, `HERMES_SSH_KEY`, and
  `ANSIBLE_BECOME_PASSWORD`. `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and
  `TOFU_STATE_PASSPHRASE` are not used.
- `HEADSCALE_AUTHKEY` is a reusable, ephemeral pre-auth key with
  `tag:github-actions`. It expires on 24 September 2036.
- Headplane gets its Headscale API key from Ansible. Ansible makes a new key
  when less than 365 days remain.
- Do not print a secret. Change a SOPS value with `sops set`. In a command for
  the owner, put `!` in single quotes, because bash history expansion breaks
  it in double quotes.

### Lessons

- Use the tailnet IP of a Proxmox node, not its MagicDNS name. Runners use
  `--accept-dns=false`, and public DNS sends `*.vnet.buildwithcaleb.com` to
  `hermes`.
- In a check run, `command` tasks do not run. Give a read-only task
  `check_mode: false`. A task or handler for a service that the check run did
  not install must skip in check mode.
- A template replaces a file with a new file. A single-file bind mount keeps
  the old file, so a container must restart after the change.
- `hermes` starts sshd from a socket. Each new connection reads the files at
  once, so validate an SSH file (`sshd -t -f %s`) before it goes in place.
- The Headscale `base_domain` must not be the host name of `server_url`, or a
  parent of it.
- Proxmox VE 9 keeps the host key of each node in
  `/etc/pve/nodes/<node>/ssh_known_hosts`. A manual SSH test between nodes
  must use that file.
- The Proxmox API token cannot change a raw USB or PCI device, make a
  privileged container, add a bind mount, or set a feature flag other than
  `nesting`.
- A VM with no `cpu` line runs `qemu64`. Proxmox makes tags lowercase.
- A Pangolin blueprint cannot delete a resource. Delete it in the UI.
- Color codes in Ansible output break `grep` in a workflow. Turn off color.
- A copy of a live SQLite file can be broken. The backup script uses
  `sqlite3 .backup` first.
- ACME for a `.vnet` name must use DNS-01. The public wildcard record sends
  the name to `hermes`, so HTTP-01 fails.
- The OpenID client of Proxmox has no PKCE, so its Pocket ID client has PKCE
  off. Proxmox names an OIDC group `<group>-<realm>`, from the group name, not
  the display name.
- The Proxmox web UI keeps the permissions of a user until the page loads
  again. After a change of groups, reload the page.
- The OpenTofu token `tofu@pve!homelab-iac` has no privilege separation. It
  uses the permissions of the user `tofu@pve` only, so give each access rule
  to the user. The user has the custom role `IaCProvisioner` on `/`.
- A download from a URL to Proxmox storage needs `Sys.AccessNetwork`. It is
  in `IaCProvisioner`. Do not give `Sys.Modify` for this.
- The pool `lethe` on `gaia` has 5 disks with 4096-byte sectors (4Kn). A QEMU
  disk shows 512-byte sectors, so a pool made in a VM has its GPT at byte
  512. The host looks at byte 4096 and finds no partition. Do not wipe the
  disk. Write a new GPT with the same partition in bytes.

### Open work

- When Headscale 0.30 is released: run a backup first, because its database
  migration cannot be reversed. Then give the pipeline an OAuth client
  (`headscale oauth-clients create --scope auth_keys --tag
  tag:github-actions`). Put
  `tskey-client-...?baseURL=https://vpn.buildwithcaleb.com` in
  `HEADSCALE_AUTHKEY`, and add `--advertise-tags=tag:github-actions`. Keep the
  `authkey` input of the action.
- Renovate closed its open pull requests after the history rewrite of
  28 September 2026. Check that it opens them again.

### Do not

- Do not add a self-hosted runner.
- Do not commit a state file or a secret in plain text, also in the history.
- Do not give `tag:github-actions` more than the Proxmox API port.
- Do not run Headscale in the homelab.
- Do not make a Pangolin resource for `vpn.buildwithcaleb.com`.

## 5. The `context/` folder

`context/` holds scratch notes for one task. Git ignores the folder, and it
stays on one machine. Read it for background. Do not commit it. If a fact must
last, put it in this file.

The owner writes the documentation of the homelab by hand. Do not add a
document to the repository unless the owner asks for it.
