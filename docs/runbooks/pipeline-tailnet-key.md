# The tailnet key of the pipeline

A GitHub Actions job joins the tailnet with the key in the GitHub secret
`HEADSCALE_AUTHKEY`. The key makes an ephemeral node with the tag
`tag:github-actions`. The policy gives that tag TCP port `8006` on
`tag:proxmox` only. See decision 6 in `AGENTS.md`.

## The current method: a pre-auth key of 3650 days

The current key has the ID 3 in `headscale preauthkeys list`. It expires on
24 September 2036.

Headscale 0.29 has no key that does not expire. A pre-auth key of 3650 days
removes the expiry as a problem. If the key leaks, the policy limits it to the
Proxmox API port, and the Proxmox API needs its own token.

Make a new key, and replace the secret:

1. Make the key on `hermes`. Copy the key from the output.

   ```sh
   ssh -t caleb@192.255.220.7 'sudo headscale preauthkeys create --reusable --ephemeral --expiration 3650d --tags tag:github-actions'
   ```

2. Replace the secret. The command asks for the value, so the key does not go
   into the shell history.

   ```sh
   gh secret set HEADSCALE_AUTHKEY
   ```

3. Test the new key. Both check steps must pass.

   ```sh
   gh workflow run tailnet-check.yml
   gh run watch
   ```

4. Expire the old key. Find its ID in the list: it is the other key with the
   tag `tag:github-actions`.

   ```sh
   ssh -t caleb@192.255.220.7 'sudo headscale preauthkeys list'
   ssh -t caleb@192.255.220.7 'sudo headscale preauthkeys expire --id <old ID>'
   ```

Warning: do step 4 only after step 3 passes. Until then, the old key is the
only key that works.

## The next method: an OAuth client

Headscale 0.30 adds OAuth clients. An OAuth client has no expiry, and each job
gets a new single-use key from it. Headscale 0.30 is not released on
27 September 2026. Task F3 in `docs/todo.md` holds the steps for the change.

Warning: the upgrade to Headscale 0.30 changes the database, and the change
cannot be reversed. Make a backup of `hermes` before the upgrade.

## Sources

- [Headscale pre-auth keys](https://headscale.net/stable/ref/registration/)
- [Headscale 0.30.0 changelog, OAuth clients](https://github.com/juanfont/headscale/blob/main/CHANGELOG.md)
