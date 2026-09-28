# The pipeline for `hermes`

The workflow `.github/workflows/ansible-hermes.yml` deploys `hermes` with
Ansible:

- **A pull request** that changes `ansible/`: lint, a syntax check, and a check
  run with `--diff` against `hermes`. The log shows each change.
- **A push to `main`**: lint, then the apply job. The apply job uses the GitHub
  environment `hermes`, so it waits for the approval of the owner. See
  decision 7 in `AGENTS.md`. After the apply, a check run must show no change,
  or the job fails.

The pipeline deploys `hermes` only. It cannot reach the Proxmox nodes: the
runner joins the tailnet as `tag:github-actions`, and the policy gives that tag
port `8006` only. See decision 3 in `AGENTS.md`.

Warning: after the pipeline works, deploy `hermes` through a pull request. Do
not run a playbook against `hermes` by hand, except to repair the pipeline.

## How the runner logs in

- The runner logs in as `iac-admin` with its own SSH key. The `admin_user` role
  makes `iac-admin` on each host, with the keys at
  `https://github.com/cnbrown04.keys` and the keys in
  `admin_user_extra_ssh_keys`. The pipeline key is in
  `admin_user_extra_ssh_keys` for `hermes` only.
- `ansible/known_hosts` holds the host key of `hermes`. SSH checks it. The key
  matched the known key of the owner on 27 September 2026.
- `iac-admin` uses sudo with a password. The hash is in
  `ansible/inventory/group_vars/all/secrets.sops.yml`. The password is the same
  on each host.

## The secrets

| Secret | Content |
| --- | --- |
| `SOPS_AGE_KEY` | The age private key. It decrypts the SOPS files. |
| `HERMES_SSH_KEY` | The private SSH key of the pipeline. |
| `ANSIBLE_BECOME_PASSWORD` | The sudo password of `iac-admin`. |

The lint job uses no secret. A pull request from a fork gets no secret, so the
check job runs only for a branch of this repository.

## The setup, one time

Run these steps from the root of the repository.

1. Make the SSH key of the pipeline. Store the private key as a secret, then
   delete it from the disk.

   ```sh
   ssh-keygen -t ed25519 -N '' -C 'github-actions hermes' -f /tmp/hermes-ci
   gh secret set HERMES_SSH_KEY < /tmp/hermes-ci
   cat /tmp/hermes-ci.pub
   shred -u /tmp/hermes-ci
   ```

2. Put the public key in `admin_user_extra_ssh_keys` in
   `ansible/inventory/host_vars/hermes/main.yml`.
3. Make `iac-admin` on `hermes`. On a new host, add `-e ansible_user=caleb`,
   because `iac-admin` does not exist yet. The role also adds `iac-admin` to
   the `AllowUsers` line of the hardening script, and checks the SSH
   configuration with `sshd -t` before the reload.

   ```sh
   cd ansible
   ansible-playbook --diff playbooks/hermes.yml -K --tags admin_user -e ansible_user=caleb
   ```

4. Test `iac-admin`:

   ```sh
   ssh -t iac-admin@192.255.220.7 'sudo -v && echo ok'
   ```

5. The noVNC console in the vPanel admin panel works without SSH. Use it if
   an SSH change locks you out.
6. Store the sudo password. The command asks for the value.

   ```sh
   gh secret set ANSIBLE_BECOME_PASSWORD
   ```

7. Make the environment `hermes` with the owner as the required reviewer, and
   allow the branch `main` only:

   ```sh
   gh api -X PUT repos/cnbrown04/homelab-iac/environments/hermes \
     --input - <<EOF
   {"reviewers": [{"type": "User", "id": $(gh api user --jq .id)}],
    "deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
   EOF
   gh api -X POST repos/cnbrown04/homelab-iac/environments/hermes/deployment-branch-policies \
     -f name=main -f type=branch
   ```

8. Open a pull request with these changes. The check job must pass. Merge it,
   and approve the apply job.
