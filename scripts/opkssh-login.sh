#!/usr/bin/env bash
# Logs in to Pocket ID with opkssh, when the key of Ansible is missing or
# older than 23 hours. The hosts refuse the key 24 hours after the login. The
# certificate itself has no end date, so the age of the file tells the age of
# the login. Run it from the root of the repository:
#
#   mise run login
#
# Set FORCE=1 to log in again now. With QUIET=1, the script prints nothing
# when no login is necessary. The callback plugin opkssh_login of Ansible
# runs this script before each run.
set -euo pipefail

key="${HOMELAB_SSH_KEY_FILE:-$HOME/.ssh/opkssh_homelab}"
cert="${key}-cert.pub"

if [[ "${FORCE:-0}" != 1 && -f "$cert" && -n "$(find "$cert" -mmin -1380)" ]]; then
  [[ "${QUIET:-0}" == 1 ]] || echo "The opkssh key is less than 23 hours old. No login is necessary."
  exit 0
fi

echo "Log in to Pocket ID in the browser."
opkssh login --config-path scripts/opkssh-client.yml --private-key-file "$key"
