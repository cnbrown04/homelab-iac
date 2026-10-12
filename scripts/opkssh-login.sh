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
#
# With OPKSSH_DEVICE_FLOW=1, the script uses the device flow: it prints a link
# and a QR code, and you log in on any device. OPKSSH_BIN sets the opkssh
# binary. The role dev_tools sets both on daedalus.
set -euo pipefail

key="${HOMELAB_SSH_KEY_FILE:-$HOME/.ssh/opkssh_homelab}"
cert="${key}-cert.pub"

if [[ "${FORCE:-0}" != 1 && -f "$cert" && -n "$(find "$cert" -mmin -1380)" ]]; then
  [[ "${QUIET:-0}" == 1 ]] || echo "The opkssh key is less than 23 hours old. No login is necessary."
  exit 0
fi

opkssh_bin="${OPKSSH_BIN:-opkssh}"
args=(--config-path scripts/opkssh-client.yml --private-key-file "$key")

if [[ "${OPKSSH_DEVICE_FLOW:-0}" == 1 ]]; then
  echo "Open the link, or scan the QR code, on any device, and log in to Pocket ID."
  exec "$opkssh_bin" login pocketid-device "${args[@]}"
fi

echo "Log in to Pocket ID in the browser."
exec "$opkssh_bin" login "${args[@]}"
