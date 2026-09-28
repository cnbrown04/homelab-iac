# The pipeline for OpenTofu

The workflow `.github/workflows/tofu.yml` plans and applies the OpenTofu
targets `atlas` and `pantheon`. It calls `.github/workflows/tofu-target.yml`
once for each target.

- **A pull request** that changes `tofu/`, `secrets/tofu.sops.yaml`, or
  `scripts/tofu-env.sh`: `tofu fmt` and `tofu validate`, then a plan for each
  target. The job summary shows each plan.
- **A push to `main`**: a plan for each target. A target with changes keeps
  the saved plan, and the apply job waits for the approval of the owner in the
  GitHub environment of the target (`atlas` or `pantheon`). See decision 7 in
  `AGENTS.md`. After the approval, the job applies the saved plan, and a new
  plan must show no change. A target with no change asks for no approval.

## How the runner reaches Proxmox

The runner joins the tailnet with `HEADSCALE_AUTHKEY`, as `tag:github-actions`.
The policy gives that tag port `8006` on `tag:proxmox` only. The provider uses
the tailnet address of the target. See `provider.tf` in each target.

## The secrets

The runner uses `scripts/tofu-env.sh`, the same script as a workstation. It
decrypts `secrets/tofu.sops.yaml` with `SOPS_AGE_KEY`, and it masks each value
in the log. So the pipeline and a workstation use the same values.

| Secret | Content |
| --- | --- |
| `SOPS_AGE_KEY` | The age private key. |
| `HEADSCALE_AUTHKEY` | The pre-auth key for the tailnet. See `pipeline-tailnet-key.md`. |

The GitHub secrets `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and
`TOFU_STATE_PASSPHRASE` are not used. `secrets/tofu.sops.yaml` holds the same
values.

OpenTofu encrypts the saved plan with the state passphrase, so the plan
artifact is not readable without the passphrase. The artifact expires after
seven days.

## The setup, one time

Make the environments `atlas` and `pantheon`, with the owner as the required
reviewer, and allow the branch `main` only:

```sh
for env in atlas pantheon; do
  gh api -X PUT "repos/cnbrown04/homelab-iac/environments/$env" --input - <<EOF
{"reviewers": [{"type": "User", "id": $(gh api user --jq .id)}],
 "deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
EOF
  gh api -X POST "repos/cnbrown04/homelab-iac/environments/$env/deployment-branch-policies" \
    -f name=main -f type=branch
done
```

## Add a VM

1. Add one entry to `vms.tf` of the target.
2. Open a pull request. Read the plan in the job summary.
3. Merge the pull request, then approve the apply job of the target.
