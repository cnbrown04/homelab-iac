# The public entry point of `hermes`

This runbook records the route for public traffic on `hermes`. It closes task
C1 in `docs/todo.md`. Ansible deploys each part.

## The names

| DNS name | Service | Pangolin login |
| --- | --- | --- |
| `pangolin.buildwithcaleb.com` | The Pangolin dashboard | Pangolin |
| `vpn.buildwithcaleb.com` | Headscale | none |
| `headplane.buildwithcaleb.com` | Headplane | Pangolin, then a Headscale API key |
| `dockge.buildwithcaleb.com` | Dockge | Pangolin, then Dockge |

Two `A` records point to `192.255.220.7`: `buildwithcaleb.com` and
`*.buildwithcaleb.com`. The wildcard record covers each name in the table and
each new Pangolin resource. The owner made the records on 27 September 2026.

## The route

1. Gerbil publishes ports `80/tcp`, `443/tcp`, `443/udp`, `51820/udp`, and
   `21820/udp`.
2. Traefik uses the network of Gerbil, and it terminates TLS.
3. Traefik sends `vpn.buildwithcaleb.com` to `http://10.200.0.1:8085`.
4. Headscale runs as a system service, and it listens on `10.200.0.1:8085`.

The address `10.200.0.1` is the gateway of the Docker network `pangolin`. The
network has the fixed subnet `10.200.0.0/24`. The address is not public.

## Two kinds of route

Traefik gets routes from two sources:

- **The file configuration.** Ansible writes it from the repository. Traefik
  serves these routes when the Pangolin app is down. The Pangolin UI does not
  show them.
- **The Pangolin database.** The UI shows these resources. Ansible creates them
  with a blueprint. Traefik sends each request through the badger middleware,
  and badger asks the Pangolin app to verify the request. When the Pangolin
  app is down, badger returns HTTP `500`.

Headscale uses the file configuration. Warning: do not make a Pangolin resource
for `vpn.buildwithcaleb.com`. The control server must not depend on the
Pangolin app. See decision 3 in `AGENTS.md`.

Headscale has no Pangolin login. A Tailscale client cannot complete a browser
login. Headscale does its own authentication with node keys.

Headplane and Dockge are Pangolin resources on the local site. The owner chose this split
on 27 September 2026. The blueprint is `pangolin_blueprint_resources` in
`ansible/inventory/host_vars/hermes/main.yml`. Change a resource there, and not
in the UI, because the next apply replaces the change.

## The firewall

UFW denies incoming traffic by default. This includes traffic from a Docker
network to the host. The Headscale role adds one rule: `10.200.0.0/24` can
reach `10.200.0.1` on TCP port `8085`.

Caution: Docker writes its own iptables rules for a published port. UFW does
not control the ports of Gerbil. Do not publish a port in a Compose file if
the port must stay private.

## The boot order

Headscale cannot bind to `10.200.0.1` before Docker creates the network. A
systemd override starts Headscale after `docker.service`.

## The first deployment

1. Make sure that each name resolves to `192.255.220.7`.
2. Run `ansible-playbook --diff playbooks/hermes.yml -K` from `ansible/`.
3. Read the setup token in the Pangolin log:

   ```sh
   sudo docker logs pangolin 2>&1 | grep -i token
   ```

4. Open `https://pangolin.buildwithcaleb.com/auth/initial-setup`. Create the
   admin account.
5. Run `ansible-playbook --diff playbooks/headscale.yml -K`.
6. Test the route. The command must return HTTP status `200`:

   ```sh
   curl -sS -o /dev/null -w '%{http_code}\n' https://vpn.buildwithcaleb.com/health
   ```

Warning: do step 4 immediately after step 2. Until you create the admin
account, any person with the setup token can take control of the dashboard.

## Headplane

Headplane runs in Docker on the `pangolin` network. It uses the listener at
`10.200.0.1:8085` for the Headscale API. Pangolin asks for its login first, and
then Headplane asks for a Headscale API key. Make a key on `hermes`:

```sh
sudo headscale apikeys create --expiration 90d
```

Headplane serves only the path `/admin`. A file route in Traefik sends the
root path of `headplane.buildwithcaleb.com` to `/admin/`. The variable is
`pangolin_root_redirects`. The route has the priority `200`, and the Pangolin
route has the priority `100`, so the redirect comes first.

Headplane can read the Headscale configuration, but it cannot change it. Ansible
owns that file and the policy file. Make a change in the repository, and deploy
it with `playbooks/headscale.yml`.

## The Enterprise Edition

Pangolin runs the Enterprise Edition image, `fosrl/pangolin:ee-<version>`. The
Community Edition and the Enterprise Edition use the same database, so the
change needs no migration. The Enterprise features stay locked until you
activate a license key. The key is free for personal use.

1. Get a free license key from Pangolin.
2. Open `https://pangolin.buildwithcaleb.com/admin/license`, and enter the key.

The license key is in the Pangolin database, and not in the repository.

## The blueprint setup

Do these steps one time. Ansible needs three values from Pangolin.

1. Open **Sites**, and add a site of the type **Local**. Record its identifier.
2. Open **API Keys** in the organization. Make a key with the permission
   **Apply Blueprint**. Record the key.
3. Record the ID of the organization. The dashboard URL shows it.
4. Put the site identifier and the organization ID in
   `ansible/inventory/host_vars/hermes/main.yml`.
5. Put the key in `secrets.sops.yml` as `pangolin_blueprint_api_key`.
6. Run `ansible-playbook --diff playbooks/pangolin_resources.yml -K`.

Ansible keeps the last applied blueprint in
`/opt/stacks/pangolin/blueprint.json`. It applies the blueprint only after a
change. Delete that file to apply the blueprint again.

## Sources

- [Pangolin manual install with Docker Compose](https://docs.pangolin.net/self-host/manual/docker-compose)
- [Headscale behind a reverse proxy](https://headscale.net/stable/ref/integration/reverse-proxy/)
- [Headplane Docker install](https://headplane.net/install/docker)
- [Pangolin blueprints](https://docs.pangolin.net/manage/blueprints)
- [Pangolin integration API](https://docs.pangolin.net/self-host/advanced/integration-api)
