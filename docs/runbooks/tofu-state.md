# The OpenTofu state store

Cloudflare R2 stores the remote state. OpenTofu encrypts each state and plan
with AES-GCM. The S3 backend uses conditional writes to lock each state.

The owner confirmed that both target roots initialized against R2. The owner
also confirmed a separate versioned backup and a successful restore test.

## R2 setup

Create one private R2 bucket for the OpenTofu state. Enable an R2 API token with
Object Read and Write access to this bucket only. Do not put the token in this
repository.

Set these environment variables before `tofu init`:

| Variable | Value |
| --- | --- |
| `AWS_ENDPOINT_URL_S3` | `https://<account-id>.r2.cloudflarestorage.com` |
| `AWS_ACCESS_KEY_ID` | The R2 access key ID |
| `AWS_SECRET_ACCESS_KEY` | The R2 secret access key |
| `TF_VAR_state_encryption_passphrase` | A random passphrase with at least 16 characters for OpenTofu state and plan encryption |

Both target roots use the bucket `homelab-iac-state` and separate state keys.
The account ID goes in `AWS_ENDPOINT_URL_S3`. Keep the access keys and the
encryption passphrase in a secret store.

On a workstation, `secrets/tofu.sops.yaml` holds these values, and SOPS
encrypts the file. `scripts/tofu-env.sh` exports them for one target, together
with the Proxmox API token of that target:

```sh
source scripts/tofu-env.sh atlas
cd tofu/targets/atlas
tofu plan
```

| Key in `secrets/tofu.sops.yaml` | Exported as |
| --- | --- |
| `r2_endpoint` | `AWS_ENDPOINT_URL_S3` |
| `r2_access_key_id` | `AWS_ACCESS_KEY_ID` |
| `r2_secret_access_key` | `AWS_SECRET_ACCESS_KEY` |
| `state_encryption_passphrase` | `TF_VAR_state_encryption_passphrase` |
| `atlas_api_token`, `pantheon_api_token` | `PROXMOX_VE_API_TOKEN` |

The pipeline uses the same file and script, with the GitHub secret
`SOPS_AGE_KEY`. See `docs/runbooks/pipeline-tofu.md`.

The target roots set separate state keys and use native S3 lock files. Do not
run `tofu init` until the R2 bucket and credentials exist. OpenTofu saves backend
settings under `.terraform/`; do not commit that directory.

## Key recovery

The state encryption passphrase is required to read the remote states and saved
plans. Store a recovery copy outside GitHub. If the passphrase is lost, OpenTofu
cannot decrypt the state. R2 does not provide object versioning, so create and
test a separate backup process before the first apply.

Do not change the passphrase after the first state write. Plan a key rollover
with an OpenTofu encryption fallback before you change it.

## Sources

- [OpenTofu S3 backend](https://opentofu.org/docs/v1.12/language/settings/backends/s3/)
- [OpenTofu state encryption](https://opentofu.org/docs/v1.12/language/state/encryption/)
- [Cloudflare R2 S3 API compatibility](https://developers.cloudflare.com/r2/api/s3/api/)
- [Cloudflare R2 token permissions](https://developers.cloudflare.com/r2/api/tokens/)
