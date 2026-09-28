#!/usr/bin/env bash
# Exports the secrets that OpenTofu needs for one target. The values come from
# secrets/tofu.sops.yaml, and SOPS decrypts them in memory only.
#
#   source scripts/tofu-env.sh atlas
#   cd tofu/targets/atlas && tofu plan
#
# See docs/runbooks/tofu-state.md.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Source this script: source scripts/tofu-env.sh <target>" >&2
  exit 1
fi

tofu_env_target="${1:-}"
case "$tofu_env_target" in
  atlas | pantheon) ;;
  *)
    echo "Give a target: atlas or pantheon." >&2
    return 1
    ;;
esac

tofu_env_file="$(git rev-parse --show-toplevel)/secrets/tofu.sops.yaml"

# Python writes one quoted export line for each value, so a value with a
# special character stays one word.
tofu_env_exports="$(
  sops decrypt --output-type json "$tofu_env_file" | python3 -c '
import json, shlex, sys
target = sys.argv[1]
data = json.load(sys.stdin)
names = {
    "AWS_ENDPOINT_URL_S3": "r2_endpoint",
    "AWS_ACCESS_KEY_ID": "r2_access_key_id",
    "AWS_SECRET_ACCESS_KEY": "r2_secret_access_key",
    "TF_VAR_state_encryption_passphrase": "state_encryption_passphrase",
    "PROXMOX_VE_API_TOKEN": target + "_api_token",
}
missing = [key for key in names.values() if not data.get(key)]
if missing:
    sys.exit("secrets/tofu.sops.yaml has no value for: " + ", ".join(missing))
for variable, key in names.items():
    print("export %s=%s" % (variable, shlex.quote(data[key])))
' "$tofu_env_target"
)" || return 1

eval "$tofu_env_exports"
unset tofu_env_exports tofu_env_file
echo "Exported the OpenTofu secrets for $tofu_env_target." >&2
unset tofu_env_target
