# Ansible

Ansible configures machines that already run. Inventory entries use the host
names of those machines. Compose files stay in this folder and Ansible deploys
them. Dockhand does not act as a deployment source.

## Set up the controller

Run these commands from this folder:

```sh
mise install
ansible-galaxy collection install -r requirements.yml
```

Ansible reads `ansible.cfg` and `inventory/hosts.yml` from this folder.

## Check `hermes`

```sh
ansible hermes -m ansible.builtin.setup -e '{"ansible_become": false}'
ansible-playbook --syntax-check playbooks/hermes.yml
ansible-playbook --syntax-check playbooks/headscale.yml
ansible-playbook --check --diff playbooks/hermes.yml -K
```

The fact command does not need sudo. The Ansible play needs the sudo password
unless `caleb` has passwordless sudo. Review the current service and firewall
settings before apply.

## Variables and secrets

`inventory/host_vars/hermes/main.yml` holds the variables for `hermes`.
`inventory/host_vars/hermes/secrets.sops.yml` holds its secrets. SOPS encrypts
that file with age. Ansible decrypts it with the `community.sops` vars plugin.
Your age key must be in `~/.config/sops/age/keys.txt`.

Run this command to change a secret:

```sh
sops inventory/host_vars/hermes/secrets.sops.yml
```

## The order of the plays

1. `playbooks/hermes.yml` installs Docker, Dockhand, and Pangolin.
2. `playbooks/headscale.yml` installs Headscale. Headscale listens on the
   gateway address of the Pangolin network, so Pangolin must run first.

`playbooks/site.yml` runs the plays in this order.

The first run on a new host cannot use `--check`. Docker is not installed, so
the tasks for Docker and Compose fail in check mode.

See `docs/runbooks/hermes-edge.md` for the route from Pangolin to Headscale.
The Dockhand stack has no published web port. Add a private proxy route only
after you create the first admin account of Dockhand.
