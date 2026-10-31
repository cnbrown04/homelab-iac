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
- Do not ask for permission to commit. The owner commits, or tells you to
  commit.
- At the end of a change that is complete, give a commit message in the
  Conventional Commits format. The owner uses it to commit.
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
| `hermes` | Public VPS, Ubuntu 24.04. The owner has a noVNC console in vPanel. | `192.255.220.7` (public) | `tag:hermes`, Wazuh only |
| `mnemosyne` | File server VM on `gaia` (VMID `200`), Debian 13. Runs Samba and OpenCloud. | `10.0.1.16` | MagicDNS |
| `daedalus` | Development VM on `tartarus` (VMID `300`), Ubuntu 24.04. | `10.0.1.17` | MagicDNS |
| `argus` | SIEM VM on `tartarus` (VMID `400`), Ubuntu 24.04. Runs Wazuh. | `10.0.1.18` | MagicDNS |

Proxmox VE is 9.2 on Debian trixie. The `pantheon` cluster runs the Talos
Kubernetes cluster `typhon`.
The web UI of each node is at `https://<host>.vnet.buildwithcaleb.com`, with a
Let's Encrypt certificate and the Pocket ID login (realm `pocketid`).
Ansible logs in to each host as `iac-admin`, with the key in
`ansible/iac-admin-key.pub` and sudo with no password. The 1Password agent
signs each login, and asks the owner to approve the first use.

### The `typhon` cluster

Talos v1.14 and Kubernetes 1.37, on VLAN 20 (`10.0.20.0/24`). The API is at
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
- Audiobookshelf is at `audiobooks.buildwithcaleb.com`, with no Pangolin
  login. It logs in with its own users and with OIDC through Pocket ID. The
  owner made its Pocket ID client by hand.
  - The books are in `/lethe/data/media/audiobooks`, mounted at `/audiobooks`.
    The metadata and the daily backups (01:30) are in
    `/lethe/k8s/audiobookshelf-metadata`. The SQLite database is on
    `local-path`.
  - The pod runs as user 1000 with the extra group 65534, so it can write
    the old covers and `metadata.json` files of `nobody`.
  - To restore the database: put a database at
    `/lethe/k8s/audiobookshelf-metadata/migrate/absdatabase.sqlite`, then
    delete the pod and the claim `config`. The init container copies it.
- Jellyfin is at `jellyfin.buildwithcaleb.com`, with no Pangolin login. It
  runs on `typhon-w-3` only, for the iGPU of `hyperion`.
  - The libraries are in `/lethe/data/media`, mounted at `/media`. The
    transcodes go to the dataset `lethe/data/media/transcode`, which user
    1000 owns. The metadata is in `/lethe/k8s/jellyfin/metadata`. The SQLite
    database and the settings are on `local-path`.
  - To restore the config: put the folders `config`, `data`, `plugins`, and
    `root` in `/lethe/k8s/jellyfin/migrate/`, then delete the pod and the
    claim `config`. The init container copies them.
- Tdarr is at `tdarr.buildwithcaleb.com`, with the Pangolin login. Its own
  login is off (`auth=false`). The server and one internal node run in one
  pod on `typhon-w-3`.
  - The GPU plugin shares the iGPU of `hyperion` with `-shared-dev-num=2`,
    so Jellyfin and Tdarr each get `gpu.intel.com/i915: 1`.
  - It mounts `/lethe/data/media` at `/media`. Its cache is
    `/lethe/data/media/tdarr-cache`, at `/temp`. Set `/temp` as the cache of
    each library. The cache is not in the transcode dataset, because Jellyfin
    deletes old files there.
  - The SQLite database and the settings are on `local-path`. The backups of
    Tdarr are on a dynamic volume of `nfs-lethe`.
  - The image starts s6 as user 1000. s6 accepts a `/run` that root owns
    only with `S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES=1`.
- Sonarr, Radarr, Prowlarr, Chaptarr, and qBittorrent are at
  `<app>.buildwithcaleb.com`, with the Pangolin login. Chaptarr manages the
  audiobooks in `/media/audiobooks`.
  - Sonarr, Radarr, Prowlarr, and Chaptarr have no login of their own
    (`<APP>__AUTH__METHOD=External`). The Pangolin login is the only login, so
    their Pangolin resources must keep SSO on. The API still needs the API
    key. qBittorrent and Jackett keep their own login.
  - Each mounts `/lethe/data/media` at `/media` (Prowlarr does not), so an
    import is a hard link.
    The root folders are `/media/tv`, `/media/anime`, and `/media/movies`.
    qBittorrent saves to `/media/downloads`.
  - Each service keeps the port of the app (`8989`, `7878`, `9696`, `8789`,
    `8080`), because the old settings of the apps use
    `http://<app>.<app>.svc.cluster.local:<port>`.
  - The SQLite databases are on `local-path`. The backups of the app are in
    `/lethe/k8s/<app>/Backups`. To restore the config: put the old config
    folder in `/lethe/k8s/<app>/migrate/`, then delete the pod and the claim
    `config`.
- qBittorrent sends each torrent through ProtonVPN, with gluetun as a sidecar
  in its pod. The firewall of gluetun drops each packet outside the tunnel,
  and qBittorrent binds to `tun0` only while the forwarded port is up. The pod
  uses the DNS of gluetun. Do not add `FIREWALL_OUTBOUND_SUBNETS`.
  `typhon-cluster/apps/qbittorrent/gluetun.sops.yaml` holds the WireGuard key.
- Jackett is at `jackett.buildwithcaleb.com`, with the Pangolin login.
  Chaptarr uses it. Its config is JSON, not SQLite, so it is on NFS in
  `/lethe/k8s/jackett/Jackett`.
- Seerr is at `seerr.buildwithcaleb.com`, with no Pangolin login. Its users
  log in with their Jellyfin accounts. It reaches Jellyfin, Sonarr, and Radarr
  by their service names. Its SQLite database and `settings.json` are on
  `local-path`. To restore: put the old config folder in
  `/lethe/k8s/seerr/migrate/`, then delete the pod and the claim `config`.
- Termix is at `termix.buildwithcaleb.com`, with no Pangolin login. It logs
  in with Pocket ID only. Registration and the password login are off in its
  admin UI, and they must stay off. The owner sets OIDC in the admin UI of
  Termix, and copies the callback URL from that page to Pocket ID. The SQLite database is
  on `local-path`.
  - A Tailscale sidecar joins the tailnet as `termix`, with `tag:termix`. It
    runs in kernel mode, as root with `NET_ADMIN`, so the namespace is
    `privileged`. Each container of the pod reaches the tailnet with no proxy.
    The policy gives `tag:termix` TCP `22`, `3389`, and `5900` on each node.
  - The SOCKS5 proxy `127.0.0.1:1055` stays for the hosts that still use it.
    A new host does not need it.
  - Each host in Termix logs in as `caleb` with the key of Termix, at its
    tailnet address. The key works only from `ssh_key_sources`, so the pod
    network cannot use it. Termix keeps the private key in its database.
  - `typhon-cluster/apps/termix/tailscale.sops.yaml` holds the join key. The
    sidecar uses it for the first login only, and keeps its state on the
    claim `tailscale`.
- The owner tests Karakeep, Sure, TaskView, and Tududi, at
  `<app>.buildwithcaleb.com`, with no Pangolin login. Karakeep is the
  bookmark manager.
  - Each app logs in with Pocket ID, with the client ID `<app>`. The login
    button and the Tududi slug use the name of the SSO, `Cerberus`. Only
    `homelab_admin` can use the clients. The owner made them by hand. The
    password login stays for when Pocket ID is down, and no app makes a new
    account.
  - Karakeep has a public client with PKCE. The first Pocket ID login links
    the account with the same email. `DISABLE_SIGNUPS` is on.
  - The first Pocket ID login of Sure asks for the Sure password one time
    (`AUTH_JIT_MODE=link_only`). Sure makes its encryption keys from
    `SECRET_KEY_BASE`. Do not set `ACTIVE_RECORD_ENCRYPTION_*`, because Sure
    then cannot read its data.
  - Tududi makes no account at a Pocket ID login. Link Pocket ID in Profile,
    Security. Tududi makes the user of `tududi.sops.yaml` at each start.
  - The SSO config of TaskView is in its UI, for the domain `gmail.com`.
    `SSO_TRUSTED_DOMAINS` skips the proof of the domain.
  - Each app keeps its data in the cluster, on `local-path`. Sure and TaskView
    have a Postgres pod each, not PlanetScale. No app has NFS or a backup.
  - Each pod runs as a user that is not root, so each namespace is
    `restricted`. Karakeep, Tududi, and the TaskView API start their own
    processes, not the entrypoint of the image.
  - Karakeep runs the migration, the web app, and the workers in one pod, with
    Meilisearch and Chrome in their own pods.
  - The TaskView API is at `/api` on the host of the web app.
- The Flux Operator manages the Flux controllers through the FluxInstance
  `flux` in `typhon-cluster/infrastructure/configs/flux/`. It has no
  `spec.sync`, because `typhon-cluster/flux/sync.yaml` keeps the source. The
  operator installs the newest 2.9 patch on its own.
  - Do not delete the FluxInstance or the HelmRelease `flux-operator`. When
    the FluxInstance goes away, the operator uninstalls Flux. The
    FluxInstance has `kustomize.toolkit.fluxcd.io/prune: disabled`.
  - The Flux Web UI is at `flux.buildwithcaleb.com`, with the Pangolin login
    in front of its Pocket ID login. The secret `flux-web-config` holds its
    OIDC client. Members of the Pocket ID group `homelab_admin` get the role
    `flux-web-admin`.
- A NetworkPolicy with `namespaceSelector: {}` does not let the Gateway in.
  The Gateway uses the Cilium identity `ingress`. Add a CiliumNetworkPolicy
  with `fromEntities: [ingress]`.
- The PlanetScale Postgres of the apps is at `us-east-5.pg.psdb.cloud:5432`,
  in the database `asphodel`, with one Postgres database for each app. Each
  `DATABASE_URL` uses `sslmode=verify-full`.
  - OpenTofu manages it in `tofu/targets/asphodel/`. To add a database, add
    one entry to `local.apps` in `databases.tf`. OpenTofu makes a role and a
    database with the same name.
  - After the apply, run `tofu -chdir=tofu/targets/asphodel output -json
    app_database_urls`, and put the URL in the SOPS file of the app. The
    state keeps the password only after the create.
  - The user name in the URL has the routing suffix of the branch. Use the
    URL of the output, not the name of the role.
  - The role `tofu` owns each database. `pscale_admin` makes each app role,
    so `tofu` has no `ADMIN` on it and cannot give it a database. Grants let
    the app make its own schemas and tables.
- To add an app to `typhon`: put it in `typhon-cluster/apps/<name>/`, with an
  HTTPRoute to the Gateway `main` in the namespace `gateway`. Add a resource to
  `pangolin_blueprint_resources`. Its target uses the site
  `{{ pangolin_typhon_site }}`, the hostname `{{ pangolin_typhon_target }}`,
  and the port `80`.

### The file server `mnemosyne`

- Samba comes from trixie-backports. An APT pin keeps the Samba packages on
  backports, and unattended-upgrades upgrades them.
- `mnemosyne` mounts `/lethe/shares` of `gaia` with virtiofs at
  `/srv/shares`, through the directory mapping `lethe-shares`. So the VM must
  stay on `gaia`.
- Each user has the folder `/lethe/shares/users/<name>`. Samba shares it as
  `<name>`, and OpenCloud shows it. Use the Pocket ID user name.
- User 3000 (`shares`) owns each file. Samba forces this user, and OpenCloud
  runs as it.
- The shares use the SMB3 POSIX extensions, for development work. A Linux
  client mounts a share with the option `posix`. Do not add `acl_xattr`.
- OpenCloud is at `files.buildwithcaleb.com`, with no Pangolin login. It runs
  in Docker on `mnemosyne` (the role `opencloud`). Newt sends the requests
  from the Pangolin site `mnemosyne` to `127.0.0.1:9200`.
  - It uses the PosixFS driver in collaborative mode. inotify tells it about
    each change of Samba, because Samba writes through the same kernel.
  - inotify does not see a change on `gaia` or through NFS. So do not export
    `/lethe/shares` with NFS, and change the files only through Samba or
    OpenCloud. OpenCloud reads the other changes at its next start.
  - OpenCloud makes the folder of a user at the first login. It refuses a
    folder that exists already, and the user then gets no files. So the role
    `samba` does not make the folder. A new user logs in to OpenCloud before
    the first use of the share.
  - OpenCloud keeps its IDs in the extended attributes of each file, and
    `.oc-nodes`, `.oc-tmp`, and `.Trash` in each folder of a user. Samba hides
    these folders with `veto files`. Do not delete the attributes.
  - The web, desktop, and mobile apps use one Pocket ID client: a public
    client with PKCE and the custom client ID `opencloud`. WebFinger gives
    the ID to the apps (`OC_OIDC_CLIENT_ID`). The owner made the client by
    hand. A desktop app older than 4.0 does not read WebFinger, so it does
    not work.
  - The role comes from the claim `groups`: `homelab_admin` gets `admin`, and
    `opencloud_users` gets `user`. A user in neither group cannot log in.
  - `opencloud init` wrote the secrets of OpenCloud to
    `/opt/stacks/opencloud/config/opencloud.yaml` at the first start. The
    accounts, the search index, and the thumbnails are in
    `/opt/stacks/opencloud/data`.
- Run its playbook by hand. No pipeline reaches it.

### The development VM `daedalus`

- The owner logs in as `caleb`, with zsh. Ansible logs in as `iac-admin`.
  `caleb` has the group `docker`.
- The role `dev_tools` installs the tools. Change the lists in
  `host_vars/daedalus/main.yml`, then run the playbook.
  - APT installs `dev_tools_apt_packages`. To delete a package, put it in
    `dev_tools_apt_absent`.
  - mise installs `dev_tools_mise_tools` for `caleb`. Ansible writes
    `~/.config/mise/config.toml`, so do not change that file on the VM. A tool
    that you delete from the map goes away on the next run.
  - Claude Code and opencode use their own installers, not mise, so they stay
    on the newest version. Each run also updates them. The mise registry gives
    opencode v1 only. opencode v2 comes from `https://opencode.ai/v2/install`.
  - Ansible writes `~/.zshrc` of `caleb`: zsh with Zap, starship, and zoxide,
    the same as the desktop of the owner. Change `templates/zshrc.j2`, not the
    file on the VM.
  - The role installs the terminfo entry of Ghostty, so SSH from Ghostty works.
  - The neovim and tmux configs of the owner are in
    `roles/dev_tools/files/dotfiles/`. Run `mise run sync:dotfiles` to copy
    them from the desktop. Ansible copies them to the VM on each run, and
    starts neovim one time with no UI when a plugin of the lock file is
    missing. That start installs the plugins and the binary of fff.nvim.
  - Claude Code reads `CLAUDE_CODE_OAUTH_TOKEN` from
    `~/.config/dev_tools/claude.zsh`. The token comes from
    `claude setup-token` on the desktop, and is valid for one year.
  - Ansible sets the keys of `dev_tools_claude_config` in `~/.claude.json`,
    for example the theme `auto`. Claude Code keeps the other keys.
  - Each run imports the opencode logins from `opencode auth export` on the
    desktop. The import adds a missing login and skips a login that exists.
    After a new login on the desktop, put the export in SOPS again.
- Ansible on `daedalus` uses the agent of the desktop, through SSH agent
  forwarding. No private key stays on the VM.
- SSH allows TCP forwarding and agent forwarding, for VS Code Remote-SSH and
  git. VS Code installs its server at the first connection.
- The VM has the tag `tag:dev` on the tailnet.
- Run its playbook by hand. No pipeline reaches it.

### The SIEM server `argus`

- `argus` runs Wazuh 4.14: the manager, the indexer, and the dashboard on one
  VM, with 4 vCPU and 8 GiB. The RackNerd VPS `iris` is too small for it.
- The role `wazuh_server` runs the installation assistant of Wazuh one time.
  The assistant makes the certificates and the passwords. Ansible then sets
  the heap of the indexer and the enrollment password.
- The passwords of the indexer users and of the API are in
  `/root/wazuh/wazuh-install-files.tar` on `argus`. The user `admin` logs in
  to the dashboard.
- APT holds each Wazuh package, so an unattended upgrade does not change the
  version. To upgrade, change `wazuh_server_version` and
  `wazuh_agent_version` together. Upgrade the server first, because an agent
  must not be newer than the manager.
- The role `wazuh_agent` puts the agent on the Proxmox nodes, `mnemosyne`,
  `daedalus`, and `hermes`. Each agent sends its events to `10.0.1.18` on TCP
  `1514`, and enrolls on TCP `1515` with `wazuh_enrollment_password`. `argus`
  has no agent, because the manager watches its own host. Talos nodes get no
  agent.
- `hermes` joins the tailnet as `tag:hermes` only for Wazuh. Its agent uses
  the tailnet address of `argus`, `100.64.0.112`. The policy gives
  `tag:hermes` TCP `1514` and `1515` on `tag:siem`, and nothing more.
  - `playbooks/hermes_tailnet.yml` runs after `headscale.yml`, because
    Headscale must have the tag in its policy before it makes the join key.
    The pipeline of `hermes` applies it.
- The dashboard is at `wazuh.buildwithcaleb.com`, with the Pangolin login in
  front of its Pocket ID login. The VM has the tag `tag:siem`, and the
  tailnet also reaches it at `https://argus.vnet.buildwithcaleb.com`.
  - The role `newt` runs Newt on `argus` as the Pangolin site `argus`. The
    target is `https://127.0.0.1:443`. Traefik does not check the self-signed
    certificate. Newt does not accept Pangolin clients.
  - Members of the Pocket ID group `homelab_admin` get the role `all_access`.
    The owner made the Pocket ID client by hand, with PKCE off. Its callback
    URL is `https://wazuh.buildwithcaleb.com/auth/openid/login`.
  - The indexer reads its security settings from an index. After a change to
    `config.yml` or `roles_mapping.yml`, a handler loads the file with
    `securityadmin.sh` and the admin certificate.
  - Each user of the dashboard calls the API of the manager as `wazuh-wui`
    (`run_as: false`). Only admins log in, so a role for each user gives
    nothing.
  - The user `admin` still logs in with its password, for when Pocket ID is
    down.
- Run its playbook by hand. No pipeline reaches it.

### The admin group of Pocket ID

- Give the admin role of a new app to the Pocket ID group `homelab_admin`.
- Make a separate group only when the app needs a different set of admins.
  Tell the owner the reason.
- The group `opencloud_users` gives the role `user` of OpenCloud to the users
  who are not admins. OpenCloud refuses a user with no role.

### The accounts on each host

- `caleb` is the account of the owner, with sudo and a password. The role
  `owner_user` makes it, with the keys at `github.com/cnbrown04.keys`.
- `iac-admin` is for Ansible and the pipelines only. The owner does not log
  in with it. It has sudo with no password, and its password is locked.
- Each user has a different key. Do not give one key to two users.
  - `iac-admin` has the key in `ansible/iac-admin-key.pub`. Its private key
    is in 1Password. `hermes` also has the pipeline key.
  - `caleb` also has the key of Termix, in `ansible/termix-key.pub`.
  - The key of `iac-admin` and the key of Termix work only from
    `ssh_key_sources`: the LAN and the tailnet. On `hermes`, the list holds
    the tailnet and the home IP of the owner.
  - `owner_user` drops the key of `iac-admin` and the key of Termix from the
    keys at the URL. So a copy on GitHub does not change the access.
  - Do not put the key of `iac-admin` or the key of Termix on GitHub. A key
    on GitHub can also push to the repositories of the owner.
- On `mnemosyne`, `caleb` is also the Samba user. The Samba role does not
  change the account.

### The services on `hermes`

`*.buildwithcaleb.com` has a wildcard DNS record to `hermes`.

| Name | Service | Route |
| --- | --- | --- |
| `vpn.buildwithcaleb.com` | Headscale 0.29.5, a system service on `10.200.0.1:8085` | Traefik file route |
| `pangolin.buildwithcaleb.com` | Pangolin Enterprise Edition, with Traefik and Gerbil | Traefik file route |
| `auth.buildwithcaleb.com` | Pocket ID, the SSO provider | Pangolin resource, no Pangolin login |
| `headplane.buildwithcaleb.com` | Headplane | Pangolin resource, no Pangolin login |
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
2. **Each tool does one job.** OpenTofu manages Proxmox guests and the
   PlanetScale Postgres. Ansible configures hosts. Do not create a VM with
   Ansible. Do not manage a VPS with OpenTofu. The owner gave PlanetScale to
   OpenTofu on 11 October 2026.
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
    The `proxmox_web` role adds the web certificate, port 443, and SSO. The
    owner logs in as `caleb`, with a key. The owner chose opkssh on
    10 October 2026, and returned to keys on 22 October 2026.
11. **Dockge is the Compose manager.** Ansible deploys each stack. Dockge does
    not.
12. **The Proxmox web UI:** an nftables rule sends port 443 to 8006. ACME uses
    the Cloudflare DNS-01 challenge, with the account `caleb@auburn.edu`.
    Members of the Pocket ID group `homelab_admin` get the role
    Administrator. `pocketid` is the default realm on the login page.
    `root@pam` stays as the fallback login. Run the role by hand: no pipeline
    reaches the nodes.

### The repository

```text
tofu/modules/{vm,lxc}/      # one guest each
tofu/targets/{atlas,pantheon}/  # one root and one state each; guests are data in vms.tf and containers.tf
tofu/targets/asphodel/      # the PlanetScale Postgres asphodel; databases are data in databases.tf
ansible/inventory/          # hosts.yml, group_vars/{all,proxmox_nodes}, host_vars/hermes
ansible/playbooks/          # site, hermes, headscale, hermes_tailnet, pangolin_resources, stacks, proxmox_nodes, proxmox_bootstrap, mnemosyne, daedalus, argus, vm_retire
ansible/roles/              # one job each
ansible/stacks/             # Compose files
secrets/tofu.sops.yaml      # R2 keys, state passphrase, Proxmox API tokens, PlanetScale service token
scripts/tofu-env.sh         # exports the OpenTofu secrets of one target
scripts/vps-harden.sh       # the first bootstrap of a new VPS
scripts/vm-rebuild.sh       # destroys a VM of pantheon and makes it again
scripts/readme-services.sh  # makes the service map of README.md
.github/workflows/          # ansible-hermes, tofu, tofu-target, typhon, lint, tailnet-check, readme-services
typhon-cluster/talos/       # talconfig.yaml, talsecret.sops.yaml; clusterconfig/ is ignored
typhon-cluster/flux/        # the entry point of Flux; the order of the Kustomizations
typhon-cluster/infrastructure/{controllers,configs}/  # the base services, for Flux
typhon-cluster/apps/        # one folder for each app
```

To add a guest, add one entry to `vms.tf` or `containers.tf`. Do not write a
new resource block.

To make a VM of `pantheon` again, run `mise run rebuild -- <host>`. The VM
needs an entry in `vms.tf` and a playbook `<host>.yml`. The script plans the
replacement and asks for the name of the VM. Then it deletes the node in
Headscale and the agent in Wazuh (`playbooks/vm_retire.yml`), applies the
plan, trusts the new host key, and runs the playbook. It deletes the disk of
the VM.

To add a service on `hermes`: put its Compose file in `ansible/stacks/<name>/`,
add `<name>` to `hermes_compose_stacks`, join the network `pangolin`, publish
no port, and add a resource to `pangolin_blueprint_resources`.

To add a host: a new VPS runs `scripts/vps-harden.sh`, then the play with
`-e ansible_user=caleb` one time. Give that run the key of `caleb` with
`-e ansible_ssh_private_key_file=<file>`, because `iac-admin` has no key on
the VPS yet. A new Proxmox node runs
`playbooks/proxmox_bootstrap.yml` as root, then `playbooks/proxmox_nodes.yml`.
Add the node to `hosts.yml` first, and to the group `pantheon` for the
cluster.

`mise.toml` holds each tool version. Renovate bumps the versions. Do not
change a version by hand.

### Working with the owner

- The agent can run a playbook with `--check`. The owner approves the key in
  1Password. The
  agent runs a playbook without `--check` only when the owner
  asks for it. For a command as root outside Ansible, give the owner the
  exact command, and ask for the output.
- Give numbered steps with complete commands. After a change of plan, give the
  complete list of steps again.
- Write each command for the owner to run from the root of the repository.
  Do not use `cd`.
- The owner pushes to `main` directly. Each push to `ansible/` or `tofu/`
  starts a pipeline that waits for the approval of the owner.

### Commands

```sh
# Ansible. mise sets ANSIBLE_CONFIG to ansible/ansible.cfg.
ansible-playbook ansible/playbooks/hermes.yml --check --diff
ansible-playbook ansible/playbooks/proxmox_nodes.yml --check --diff

# OpenTofu
source scripts/tofu-env.sh atlas
tofu -chdir=tofu/targets/atlas plan

# The same checks as mise tasks. Put more flags after --.
mise run check:hermes -- --tags pangolin
mise run plan:pantheon
```

### The pipelines

- `ansible-hermes.yml`: the lint and a check with `--diff` run in two jobs
  at the same time. On a push to `main`, an apply follows only when the lint
  passes and the check shows a change. It waits for
  approval in the environment `hermes`. Then a second check must show no
  change. A run by hand with `force` applies also with no change, because a
  check does not run `command` tasks.
- `tofu.yml`: lint, then a plan of each target. On a push to `main`, a plan
  with changes waits for approval in the environment `atlas`, `pantheon`, or
  `asphodel`. The job of `asphodel` does not join the tailnet.
  Then the job applies the saved plan, and a new plan must show no change. A
  plan with no change needs no approval. The plan of a pull request does not
  lock the state, because no job applies it.
- After a failed apply, start a new run. The saved plan is stale.
- A change to `mise.toml` starts `ansible-hermes.yml`, `tofu.yml`, or
  `typhon.yml` only when it changes a tool of that workflow. The action
  `.github/actions/changes` makes this decision.
- `typhon.yml` builds each Flux path and validates it with kubeconform. It
  does not deploy. Run talhelper and talosctl by hand. Flux in the cluster
  pulls from GitHub.
- `lint.yml` runs shellcheck, and checks that each SOPS file is encrypted. It
  runs for each change.
- `readme-services.yml` runs `scripts/readme-services.sh` after a change to
  it, and commits the service map in `.github/assets/`. When you add, move,
  or delete an app, a VM, or a host, change the lists in that script too. Do
  not change the SVG files by hand.
- Each job installs its tools with `.github/actions/mise-install`. Its cache
  key uses only the versions of those tools, so a bump of a different tool
  does not empty the cache.
- Renovate puts each patch update, and each minor update of version 1.0 or
  later, in one pull request with the branch `renovate/safe-updates`. A
  major update, a minor update before 1.0, a minor update of Python, Talos,
  and `ansible-core` with Mitogen keep their own pull requests.
- mise does not compile Python. Renovate waits 7 days for a new Python, so a
  precompiled build exists. It waits 3 days for each other bump of code that
  the pipelines run with the secrets.
- Each Monday at 12:00 UTC, `ansible-hermes.yml` and `tofu.yml` look for
  drift. The run fails when the check or the plan shows a change. It does not
  apply.
- In `ansible-hermes.yml`, the lint job gets no secret. Only the steps that
  use `SOPS_AGE_KEY` get it.
- The Proxmox nodes are not in a pipeline, because the tailnet policy blocks
  SSH. Run their playbook by hand. The owner chose this on 28 September 2026.
  Do not open SSH to `tag:proxmox` for a pipeline. OpenTofu still deploys the
  guests through the API.

### Secrets

- SOPS files:

  | File | Content |
  | --- | --- |
  | `secrets/tofu.sops.yaml` | R2 keys, state passphrase, Proxmox API tokens, the PlanetScale service token |
  | `ansible/inventory/group_vars/all/secrets.sops.yml` | The hash of the sudo password of `caleb`, the enrollment password of Wazuh |
  | `ansible/inventory/group_vars/proxmox_nodes/secrets.sops.yml` | The Cloudflare DNS token, the Proxmox OIDC client |
  | `ansible/inventory/host_vars/hermes/secrets.sops.yml` | The secrets of the services on `hermes`, the backup keys, the home IP of the owner |
  | `ansible/inventory/host_vars/mnemosyne/secrets.sops.yml` | The password of each Samba user, the secret of the Newt site `mnemosyne` |
  | `ansible/inventory/host_vars/daedalus/secrets.sops.yml` | The logins of Claude Code and opencode for `caleb` |
  | `secrets/typhon-age-key.sops.yaml` | The private age key of `typhon`. Flux uses it as the secret `sops-age`. |
  | `typhon-cluster/talos/talsecret.sops.yaml` | The secrets of Talos. The owner key only. |

- GitHub secrets: `SOPS_AGE_KEY`, `HEADSCALE_AUTHKEY`, and `HERMES_SSH_KEY`.
  `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `TOFU_STATE_PASSPHRASE`, and
  `ANSIBLE_BECOME_PASSWORD` are not used.
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
- Ansible gathers the facts of a host one time for each run
  (`gathering = smart`), and keeps them for 30 minutes. Each play gathers
  `min` and `network` only. A task that needs facts after a change runs
  `ansible.builtin.setup` itself. Delete `~/.cache/ansible/facts/homelab-iac`
  to clear the cache.
- Ansible uses the Mitogen strategy (`mitogen_linear`). mise installs Mitogen
  in the environment of `ansible-core` with `uvx_args`. Renovate bumps the two
  in one pull request. ansible-core deprecates third-party strategy plugins.
  If Mitogen fails, delete `strategy_plugins` and `strategy` from
  `ansible.cfg`. Each task still works without Mitogen, but more slowly.
- Use the canonical value of a ZFS property, for example `acltype: posix`
  and not `posixacl`. With an alias, each check shows a change.
- A `proxmox_download_file` has `overwrite = false`. The file name holds the
  version. With `true`, each refresh asks the URL for the size, and the Talos
  Image Factory took more than 2 minutes.
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
- The repository is public, so each pipeline log is public. GitHub does not
  mask a value that SOPS decrypts. If a task writes a SOPS value to a file,
  give the task `no_log: true`.
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
- The delete of a file in storage needs `Datastore.Allocate`. `tofu@pve`
  has the role `PVEDatastoreAdmin` on `/storage/local` only, so a new image
  can replace the old file. The owner chose this on 10 October 2026.
- Samba on `mnemosyne` does not see a change that another process makes, for
  example OpenCloud. So `smb.conf` turns off oplocks and leases. With a
  lease, a client shows an old folder list.
- Do not put `sslrootcert=system` in the `DATABASE_URL` of an app. The `pg`
  driver of Node.js reads it as a file path and fails. Only libpq (`psql`,
  `pg_dump`) needs it, so the backup job sets `PGSSLROOTCERT=system`.
- A GitHub release can come before its container image. Before you pin a
  tag, make sure that the registry has it.
- If the Cilium operator starts while the Kubernetes API is down, it starts
  with no Gateway API controller. The old routes still work, but a new
  HTTPRoute gets no status, and the Gateway gives `404`. After a restart of
  the control plane, delete the pods of `cilium-operator` in `kube-system`.
- The manager `helm` of the first Cilium install still owns some fields of
  the Cilium objects. When a new chart deletes a field, `helm-controller`
  gives up its part, but the old value stays. So set each Cilium default
  that must change in `values.yaml`. Cilium 1.20.4 deleted
  `envoy-xds-mode`, the agent kept `ads`, Envoy changed to `split`, and no
  new pod got a network.
- The annotation `glance/icon` of glance-k8s takes `di:`, `si:`, or a URL.
  It does not know `sh:`, so give a selfh.st icon as its full URL. Glance
  itself knows `sh:` and `auto-invert`.
- The level `restricted` refuses a probe with `host`. A sidecar that gives a
  health endpoint must listen on the pod IP.
- tailscaled sets the mode of its state folder. Put the state in a folder in
  the volume, not at the root, because the user does not own the root.
- Do not use the Ubuntu 26.04 cloud image. Its initramfs (dracut) starts
  DHCP, so cloud-init cannot set the static IP. Use 24.04.
- A change to `import_from` does not replace a VM. To make a VM again from a
  new image, run `mise run rebuild -- <host>`. The address for `-replace` is
  `module.vm["<host>"].proxmox_virtual_environment_vm.this`, not the module.
- cloud-init gives `iac-admin` an SSH key and no password. Ansible deletes
  the key at the first run. Log in to the console as `caleb`.
- The first run on a new VM uses the cloud-init key, because the key of
  `iac-admin` is not on the VM yet. `ansible/cloud-init-key.pub` holds the public key. SSH gets
  the private key from the 1Password agent.
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

## 5. Select the language for a backend

These rules apply when an agent writes a service. They also apply when an
agent recommends an app to self-host.

### Terms

- A **backend** is a program that runs as a service. It answers requests,
  runs jobs, or keeps a connection open. An API, a worker, a daemon, and
  server-side rendering are each a backend.
- A **frontend** is code that runs in the browser of the user.
- A **tool** is a program that a person or a pipeline starts. It stops when
  its job is complete. A tool is not a backend.

### Rules

- Write a backend in Go, Rust, C, C++, C#, Java, or Ruby.
- You can write a backend in JavaScript or TypeScript if Deno or Bun runs
  it.
- Do not write a backend in Python or PHP.
- Do not run a backend on Node.js.
- Write a frontend in JavaScript or TypeScript if you must.
- If a project has a frontend and a backend, write the backend in an
  approved language, on an approved runtime.
- Use the server part of a full-stack framework, for example Next.js, Nuxt,
  or SvelteKit, only on Deno or Bun. If the framework needs Node.js, build
  the frontend as static files, and write a separate backend.
- Look at the language and the runtime of the backend when you recommend an
  app. The language of its frontend is not important.
- If no good app with an approved language and runtime exists, you can
  recommend an app that breaks this rule. Tell the owner that the app breaks
  the rule, and give the reason for the choice.

### Exceptions

- Write a new tool in bash, or in a language of the rules above. Ansible, an
  Ansible module, a script in `scripts/`, and a step in a workflow are tools.
- Do not write Python. Use Python only when no other option exists, for
  example an Ansible module or a plugin for an app in Python. Tell the
  owner the reason.
- A plugin for an app uses the language of that app. For example, an
  integration for Home Assistant uses Python.
- The apps that run in the homelab now stay. Pangolin, Headplane, Seerr,
  Audiobookshelf, and Home Assistant are examples. Do not recommend to
  replace an app only because of this rule.
- These rules apply only when you select or recommend an app. If the owner
  names an app, the owner chose it. Do not tell the owner that its language
  or its runtime breaks this rule.

## 6. The `context/` folder

`context/` holds scratch notes for one task. Git ignores the folder, and it
stays on one machine. Read it for background. Do not commit it. If a fact must
last, put it in this file.

The owner writes the documentation of the homelab by hand. Do not add a
document to the repository unless the owner asks for it.

## 7. Keep Glance current

Glance at `home.buildwithcaleb.com` shows the state of the homelab. Its
config is `typhon-cluster/apps/glance/glance.yml`. Each change to the homelab
must also change Glance in the same change.

- When you add, move, or delete an app, a host, or a service, update each
  page of Glance that shows it.
- On the page "Services", give each app a site in a `monitor` widget. Give
  each site a `check-url` that the cluster can reach.
- Add the repository of each app to the `releases` widget of its page.
- Give each Deployment in `typhon` the annotations `glance/name` and
  `glance/icon`, so the widget "typhon apps" shows it.
- When you delete an app, also delete it from each widget.
- After the change, run `scripts/glance-preview.sh` and look at each page.
