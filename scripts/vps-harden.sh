#!/usr/bin/env bash
# shellcheck shell=bash
#
# A guard for the shell. `curl ... | sh` starts dash on Debian, and dash does
# not have the syntax of bash. This test uses POSIX syntax, so dash can read it.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "Failure: run this script with bash, and not with sh." >&2
  echo "  curl -fsSL <the URL> | sudo bash" >&2
  exit 1
fi
#
# vps-harden.sh — the first bootstrap of a new VPS.
#
# The script runs du_setup (https://github.com/buildplan/du_setup, MIT) one
# time, before Ansible takes control. Ansible owns the configuration after the
# first run. See AGENTS.md, decision 2.
#
# The script downloads du_setup at a fixed commit and checks its SHA-256. It
# reads the SSH keys of the owner from GitHub. Then it runs du_setup with no
# question (--quiet), with the settings below.
#
# du_setup does only the work that must come before Ansible: the user caleb
# with sudo and the keys, SSH with keys only on port 22, UFW, and automatic
# updates. Ansible installs Fail2ban, CrowdSec, Docker, Tailscale, and the
# kernel settings, so du_setup does not.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cnbrown04/homelab-iac/main/scripts/vps-harden.sh | sudo bash
#
# To set the hostname, give DU_HOSTNAME:
#   curl -fsSL <the URL> | sudo DU_HOSTNAME=iris bash
#
# To upgrade du_setup, change DU_SETUP_COMMIT and DU_SETUP_SHA256 together.
# Read the diff of du_setup.sh between the two commits first.
#
set -euo pipefail

readonly DU_SETUP_COMMIT="5d2a534742f1058111cdfe21c840dbab257db0ae" # v0.82.2
readonly DU_SETUP_SHA256="a94482a4bae7fc13e278b0e3fe1e6adc4fa34000f2e5741d08a4aea2afae1560"
readonly DU_SETUP_URL="https://raw.githubusercontent.com/buildplan/du_setup/${DU_SETUP_COMMIT}/du_setup.sh"

# The same user and key URL as owner_user in group_vars/all/main.yml.
readonly OWNER_USER="caleb"
readonly OWNER_KEYS_URL="https://github.com/cnbrown04.keys"

die() {
  echo "Failure: $*" >&2
  exit 1
}

[[ "${EUID}" -eq 0 ]] || die "run this script as root, for example with sudo."
command -v curl > /dev/null 2>&1 || die "install curl first: apt-get install -y curl"
command -v sha256sum > /dev/null 2>&1 || die "the command sha256sum is missing."

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

echo "Download du_setup at commit ${DU_SETUP_COMMIT}."
curl -fsSL --proto '=https' -o "${work_dir}/du_setup.sh" "${DU_SETUP_URL}"
printf '%s  %s\n' "${DU_SETUP_SHA256}" "${work_dir}/du_setup.sh" | sha256sum -c --quiet - \
  || die "the SHA-256 of du_setup.sh is not correct. The script stops."

echo "Read the SSH keys of ${OWNER_USER} from ${OWNER_KEYS_URL}."
keys="$(curl -fsSL --proto '=https' "${OWNER_KEYS_URL}")"
# Keep only lines with a key type. A FIDO2 key starts with sk-.
keys="$(grep -E '^(sk-)?(ssh|ecdsa)-' <<< "${keys}" || true)"
[[ -n "${keys}" ]] || die "the URL gave no SSH key. The script stops, so it does not lock you out."
# du_setup reads more than one key from DU_SSH_PUBLIC_KEY, with | between.
keys="$(paste -sd '|' <<< "${keys}")"

# du_setup reads only DU_* lines from this file, and does not run it. An
# environment variable, for example DU_HOSTNAME, wins over the file.
config="${work_dir}/du_setup.env"
install -m 600 /dev/null "${config}"
cat > "${config}" <<EOF
DU_USERNAME="${OWNER_USER}"
DU_USE_EXISTING_USER="true"
DU_SSH_PUBLIC_KEY="${keys}"
DU_SSH_PORT="22"
DU_TIMEZONE="Etc/UTC"
DU_USER_PASSWORD=""
DU_GENERATE_RANDOM_PASSWORD="true"
DU_PASSWORDLESS_SUDO="false"
DU_INSTALL_CUSTOM_BASHRC="false"
DU_ALLOW_HTTP="false"
DU_ALLOW_HTTPS="false"
DU_ALLOW_TAILSCALE_UDP="false"
DU_CUSTOM_UFW_PORTS=""
DU_IDS="none"
DU_ENABLE_AUTO_UPDATES="true"
DU_ENABLE_SECURE_DNS="false"
DU_ENABLE_KERNEL_HARDENING="false"
DU_INSTALL_DOCKER="false"
DU_DOCKER_UFW_HARDEN="false"
DU_INSTALL_DTOP="false"
DU_VPN="none"
DU_CONFIGURE_SWAP="false"
DU_RUN_SECURITY_AUDIT="false"
DU_RUN_DEBSECAN="false"
DU_AUTO_REBOOT="false"
EOF

echo "Run du_setup."
bash "${work_dir}/du_setup.sh" --config "${config}" --quiet < /dev/null

cat <<EOF

du_setup is complete. Do these steps before you close this session:
1. From a second terminal, log in as ${OWNER_USER} with your key.
2. Read the sudo password in /home/${OWNER_USER}/.du_initial_sudo_password.
3. Run the first Ansible play with that password (see AGENTS.md).
EOF
