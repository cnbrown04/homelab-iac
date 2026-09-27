# The public entry point of `hermes`

This runbook records the route for public traffic on `hermes`. It closes task
C1 in `docs/todo.md`. Ansible deploys each part.

## The names

| DNS name | Service | Pangolin login |
| --- | --- | --- |
| `pangolin.buildwithcaleb.com` | The Pangolin dashboard | Pangolin |
| `vpn.buildwithcaleb.com` | Headscale | none |
| `vpn.buildwithcaleb.com/admin` | Headplane | a Headscale API key |

Two `A` records point to `192.255.220.7`: `buildwithcaleb.com` and
`*.buildwithcaleb.com`. The wildcard record covers each name in the table and
each new Pangolin resource. The owner made the records on 27 September 2026.

## The route

1. Gerbil publishes ports `80/tcp`, `443/tcp`, `443/udp`, `51820/udp`, and
   `21820/udp`.
2. Traefik uses the network of Gerbil, and it terminates TLS.
3. Traefik sends `vpn.buildwithcaleb.com` to `http://10.200.0.1:8085`.
4. Headscale runs as a system service, and it listens on `10.200.0.1:8085`.

Traefik sends the path `/admin` on `vpn.buildwithcaleb.com` to the Headplane
container, on the `pangolin` network. Headplane uses the same listener at
`10.200.0.1:8085` for the Headscale API.

The address `10.200.0.1` is the gateway of the Docker network `pangolin`. The
network has the fixed subnet `10.200.0.0/24`. The address is not public.

The route for Headscale is in the file configuration of Traefik, and not in
the Pangolin database. Ansible writes it. Do not make a Pangolin resource for
`vpn.buildwithcaleb.com`.

Headscale has no Pangolin login. A Tailscale client cannot complete a browser
login. Headscale does its own authentication with node keys.

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

Headplane asks for a Headscale API key at login. Make a key on `hermes`:

```sh
sudo headscale apikeys create --expiration 90d
```

Headplane can read the Headscale configuration, but it cannot change it. Ansible
owns that file and the policy file. Make a change in the repository, and deploy
it with `playbooks/headscale.yml`.

## Sources

- [Pangolin manual install with Docker Compose](https://docs.pangolin.net/self-host/manual/docker-compose)
- [Headscale behind a reverse proxy](https://headscale.net/stable/ref/integration/reverse-proxy/)
- [Headplane Docker install](https://headplane.net/install/docker)
