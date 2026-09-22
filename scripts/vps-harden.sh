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
# vps-harden.sh — protect a new VPS against an attacker.
#
# This script is a one-time bootstrap. Run it on a new host, one time, before
# Ansible takes control. Ansible owns the configuration after the first run.
# See AGENTS.md, decision 2, and docs/runbooks/vps-bootstrap.md.
#
# The script uses whiptail, the text interface of Debian and Ubuntu.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cnbrown04/homelab-iac/main/scripts/vps-harden.sh | sudo bash
#
# The script also runs from a file:
#   sudo ./vps-harden.sh
#
set -euo pipefail

readonly LOG_FILE="/var/log/vps-harden.log"
readonly SSHD_DROPIN="/etc/ssh/sshd_config.d/99-hardening.conf"
readonly SYSCTL_FILE="/etc/sysctl.d/99-hardening.conf"
readonly BACKTITLE="VPS hardening"
readonly SCRIPT_URL="https://raw.githubusercontent.com/cnbrown04/homelab-iac/main/scripts/vps-harden.sh"

# The answers from the operator. The script collects them before it makes a
# change, so the work runs without a question.
ADMIN_USER=""
ADMIN_KEY=""
SSH_PORT=""
NEW_SSH_PORT=""
EXTRA_PORTS=""
TRUSTED_IP=""
TASKS=""
RESULTS=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
  printf '%s  %s\n' "$(date --iso-8601=seconds)" "$*" >> "$LOG_FILE"
}

# Record the result of one task. The script shows the list at the end.
record() {
  RESULTS+="$1"$'\n'
  log "$1"
}

die() {
  local message="$1"
  log "FAILURE: ${message}"
  if command -v whiptail > /dev/null 2>&1; then
    # The box is a help, and not a need. A failure here must not hide the text.
    tui --title "Failure" --msgbox "${message}" 12 70 || true
  fi
  restore_terminal
  printf 'Failure: %s\n' "${message}" >&2
  exit 1
}

# Run a command. Send the output to the log file only.
run() {
  log "RUN: $*"
  if ! "$@" >> "$LOG_FILE" 2>&1; then
    die "The command failed: $*

Read ${LOG_FILE} for the output."
  fi
}

has_task() {
  [[ " ${TASKS} " == *" $1 "* ]]
}

# ---------------------------------------------------------------------------
# Checks before the start
# ---------------------------------------------------------------------------

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    printf 'Failure: run this script as root. Use sudo.\n' >&2
    exit 1
  fi
}

require_apt() {
  if ! command -v apt-get > /dev/null 2>&1; then
    printf 'Failure: this script needs Debian or Ubuntu. It uses apt-get.\n' >&2
    exit 1
  fi
}

# Run whiptail. It reads the keyboard from /dev/tty, and not from stdin.
#
# The reason: `curl ... | bash` gives the script to bash on stdin. bash and
# whiptail cannot both read one file descriptor. The arrow keys go to bash, and
# the terminal shows ^[OA instead.
tui() {
  whiptail --backtitle "$BACKTITLE" "$@" < /dev/tty
}

# whiptail puts the terminal in the mode for an application. A failure leaves
# the terminal in that mode, and the arrow keys make ^[OA. Put the mode back.
restore_terminal() {
  [[ -e /dev/tty ]] || return 0
  printf '\033[?1l\033>\033[?25h' > /dev/tty 2> /dev/null || true
  stty sane < /dev/tty 2> /dev/null || true
}

# The script comes from a pipe, so bash reads it from stdin. Get the script
# again as a file, then start it again. bash then reads the file, and stdin
# stays free for the keyboard.
relaunch_from_file() {
  # A file or a terminal on stdin needs no change.
  [[ -t 0 ]] && return 0
  # The second start must not start a third one.
  [[ -n "${VPS_HARDEN_CHILD:-}" ]] && return 0

  if ! ( exec < /dev/tty ) 2> /dev/null; then
    printf 'Failure: the script has no terminal, so it cannot show the menu.\n' >&2
    printf 'Run the script from a terminal of SSH.\n' >&2
    exit 1
  fi

  local getter
  if command -v curl > /dev/null 2>&1; then
    getter="curl -fsSL"
  elif command -v wget > /dev/null 2>&1; then
    getter="wget -qO-"
  else
    printf 'Failure: the host has no curl and no wget.\n' >&2
    exit 1
  fi

  local tmp
  tmp="$(mktemp /tmp/vps-harden.XXXXXX.sh)"
  if ! ${getter} "${SCRIPT_URL}" > "${tmp}" 2> /dev/null; then
    rm -f "${tmp}"
    printf 'Failure: the script cannot get %s\n' "${SCRIPT_URL}" >&2
    exit 1
  fi
  # A short file means the download failed. Do not run it.
  if [[ "$(wc -c < "${tmp}")" -lt 1000 ]]; then
    rm -f "${tmp}"
    printf 'Failure: the file from %s is too short.\n' "${SCRIPT_URL}" >&2
    exit 1
  fi

  export VPS_HARDEN_CHILD=1
  export VPS_HARDEN_TMP="${tmp}"
  exec bash "${tmp}" "$@" < /dev/tty
}

require_whiptail() {
  if command -v whiptail > /dev/null 2>&1; then
    return
  fi
  printf 'The program whiptail is absent. The script installs it now.\n'
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq whiptail
}

# Find the port and the address of the current SSH session. The script keeps
# this session alive.
detect_session() {
  SSH_PORT="$(awk '/^[Pp]ort[ \t]/ { print $2; exit }' /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.d/*.conf 2> /dev/null || true)"
  [[ -n "${SSH_PORT}" ]] || SSH_PORT=22

  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    TRUSTED_IP="$(printf '%s' "${SSH_CONNECTION}" | awk '{ print $1 }')"
  elif [[ -n "${SSH_CLIENT:-}" ]]; then
    TRUSTED_IP="$(printf '%s' "${SSH_CLIENT}" | awk '{ print $1 }')"
  else
    # sudo deletes SSH_CONNECTION from the environment. Ask the terminal.
    TRUSTED_IP="$(who am i 2> /dev/null | sed -n 's/.*(\(.*\))$/\1/p')"
  fi

  # A name is not an address. Keep an address only.
  [[ "${TRUSTED_IP}" =~ ^[0-9a-fA-F.:]+$ ]] || TRUSTED_IP=""
}

# ---------------------------------------------------------------------------
# The questions
# ---------------------------------------------------------------------------

show_welcome() {
  tui --title "Before you start" --yesno \
"This script protects a VPS against an attacker.

WARNING: a mistake in the configuration of SSH can lock you out of the
host. Keep this session open until you test a new session.

The script writes ${LOG_FILE}.

Do you want to continue?" 18 72 || exit 0
}

choose_tasks() {
  TASKS="$(tui --title "Tasks" --checklist \
"Select each task. Use SPACE to select, and TAB to move to OK." 20 74 10 \
    "updates"  "Install the updates, and turn on the automatic updates" ON \
    "user"     "Create an admin user with an SSH key"                  ON \
    "ssh"      "Protect SSH: no root login, and no password"           ON \
    "ufw"      "Set up the firewall UFW"                               ON \
    "fail2ban" "Install Fail2ban for SSH"                              ON \
    "crowdsec" "Install CrowdSec and the bouncer for the firewall"     ON \
    "sysctl"   "Protect the kernel with sysctl"                        ON \
    3>&1 1>&2 2>&3)" || exit 0

  TASKS="${TASKS//\"/}"
  [[ -n "${TASKS}" ]] || die "You selected no task."
}

ask_admin_user() {
  has_task user || return 0

  ADMIN_USER="$(tui --title "The admin user" \
    --inputbox "Give the name of the admin user. The user gets sudo." \
    10 70 "admin" 3>&1 1>&2 2>&3)" || exit 0

  [[ "${ADMIN_USER}" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] \
    || die "The name '${ADMIN_USER}' is not a correct name for a user."
  [[ "${ADMIN_USER}" != "root" ]] || die "Do not use root as the admin user."

  ADMIN_KEY="$(tui --title "The public key" \
    --inputbox \
"Paste the public SSH key of the user.

The key starts with ssh-ed25519 or ssh-rsa." 12 74 "" 3>&1 1>&2 2>&3)" || exit 0

  local key_file
  key_file="$(mktemp)"
  printf '%s\n' "${ADMIN_KEY}" > "${key_file}"
  if ! ssh-keygen -l -f "${key_file}" > /dev/null 2>&1; then
    rm -f "${key_file}"
    die "That text is not a correct public SSH key."
  fi
  rm -f "${key_file}"
}

ask_ssh_port() {
  has_task ssh || return 0

  NEW_SSH_PORT="$(tui --title "The port of SSH" \
    --inputbox \
"The current port is ${SSH_PORT}.

Keep this port, or give a new port. A high port makes less noise in the
log, but it is not a protection." 13 74 "${SSH_PORT}" 3>&1 1>&2 2>&3)" || exit 0

  [[ "${NEW_SSH_PORT}" =~ ^[0-9]+$ ]] && (( NEW_SSH_PORT > 0 )) \
    && (( NEW_SSH_PORT < 65536 )) || die "The port ${NEW_SSH_PORT} is not valid."
}

ask_extra_ports() {
  has_task ufw || return 0

  EXTRA_PORTS="$(tui --title "The open ports" \
    --inputbox \
"Give each other port that must stay open. Put a space between two ports.
Add /udp for a port of UDP.

The firewall blocks every other port. The port of SSH is always open.

Example: 80/tcp 443/tcp 51820/udp" 15 74 "80/tcp 443/tcp" 3>&1 1>&2 2>&3)" \
    || exit 0
}

ask_trusted_ip() {
  has_task fail2ban || has_task crowdsec || return 0

  TRUSTED_IP="$(tui --title "Your address" \
    --inputbox \
"Fail2ban and CrowdSec do not ban this address.

The script found the address of this session. Correct it if it is wrong.
Leave it empty if you want no exception." 14 74 "${TRUSTED_IP}" \
    3>&1 1>&2 2>&3)" || exit 0
}

confirm_start() {
  local summary="The script does this work:

"
  has_task updates  && summary+="  - Install the updates.
"
  has_task user     && summary+="  - Create the user ${ADMIN_USER}.
"
  has_task ssh      && summary+="  - Protect SSH on port ${NEW_SSH_PORT}.
"
  has_task ufw      && summary+="  - Turn on UFW. Open: ${NEW_SSH_PORT:-${SSH_PORT}} ${EXTRA_PORTS}
"
  has_task fail2ban && summary+="  - Install Fail2ban.
"
  has_task crowdsec && summary+="  - Install CrowdSec.
"
  has_task sysctl   && summary+="  - Protect the kernel.
"
  summary+="
Do you want to start?"

  tui --title "Confirm" --yesno "${summary}" \
    22 74 || exit 0
}

# ---------------------------------------------------------------------------
# The tasks
# ---------------------------------------------------------------------------

task_updates() {
  export DEBIAN_FRONTEND=noninteractive
  run apt-get update -qq
  run apt-get -y -qq upgrade
  run apt-get install -y -qq unattended-upgrades apt-listchanges

  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  run systemctl enable --now unattended-upgrades
  record "OK   updates: the host is current, and it updates itself."
}

task_user() {
  if id -u "${ADMIN_USER}" > /dev/null 2>&1; then
    log "The user ${ADMIN_USER} exists. The script keeps it."
  else
    run adduser --disabled-password --gecos "" "${ADMIN_USER}"
  fi

  local group="sudo"
  getent group sudo > /dev/null 2>&1 || group="wheel"
  run usermod -aG "${group}" "${ADMIN_USER}"

  local home ssh_dir keys
  home="$(getent passwd "${ADMIN_USER}" | cut -d: -f6)"
  ssh_dir="${home}/.ssh"
  keys="${ssh_dir}/authorized_keys"

  install -d -m 700 -o "${ADMIN_USER}" -g "${ADMIN_USER}" "${ssh_dir}"
  touch "${keys}"
  # Add the key one time only. A second run of the script adds no copy.
  if ! grep -qxF "${ADMIN_KEY}" "${keys}" 2> /dev/null; then
    printf '%s\n' "${ADMIN_KEY}" >> "${keys}"
  fi
  chmod 600 "${keys}"
  chown "${ADMIN_USER}:${ADMIN_USER}" "${keys}"

  record "OK   user: ${ADMIN_USER} has sudo and the SSH key."
}

# Refuse to close the door if no key can open it.
verify_key_exists() {
  local user="$1" home keys
  home="$(getent passwd "${user}" 2> /dev/null | cut -d: -f6)" || return 1
  keys="${home}/.ssh/authorized_keys"
  [[ -s "${keys}" ]]
}

task_ssh() {
  local allow_user="${ADMIN_USER}"

  if [[ -z "${allow_user}" ]]; then
    # The operator did not create a user in this run. Find a user that has a
    # key and sudo, or stop.
    local candidate
    for candidate in $(getent group sudo 2> /dev/null | cut -d: -f4 | tr ',' ' '); do
      if verify_key_exists "${candidate}"; then
        allow_user="${candidate}"
        break
      fi
    done
  fi

  [[ -n "${allow_user}" ]] || die \
"No user has an SSH key and sudo.

The script stops. A change to SSH now locks you out of the host.
Run the script again, and select the task 'user'."

  verify_key_exists "${allow_user}" || die \
"The user ${allow_user} has no key in authorized_keys.

The script stops, because a change to SSH now locks you out."

  # Open the new port in the firewall first. The reverse order locks you out.
  if has_task ufw && command -v ufw > /dev/null 2>&1; then
    run ufw allow "${NEW_SSH_PORT}/tcp"
  fi

  install -d -m 755 /etc/ssh/sshd_config.d

  cat > "${SSHD_DROPIN}" <<EOF
# The hardening of SSH. vps-harden.sh wrote this file.
Port ${NEW_SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
AuthenticationMethods publickey
MaxAuthTries 3
MaxSessions 4
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ${allow_user}
EOF

  # An old version of sshd does not read the folder sshd_config.d. Add the
  # line that includes the folder.
  if ! grep -qE '^\s*Include\s+/etc/ssh/sshd_config\.d/\*\.conf' \
    /etc/ssh/sshd_config; then
    log "The main file has no Include line. The script adds it at the top."
    cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%s)"
    sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
  fi

  # Test the configuration before the restart. A bad file stops sshd.
  if ! sshd -t >> "$LOG_FILE" 2>&1; then
    rm -f "${SSHD_DROPIN}"
    die "The new configuration of SSH is not valid. The script deleted it.

Read ${LOG_FILE}."
  fi

  # A change of the port needs a restart, because the socket changes.
  if systemctl list-unit-files 2> /dev/null | grep -q '^ssh\.socket'; then
    run systemctl restart ssh.socket || true
  fi
  run systemctl restart ssh

  record "OK   ssh: port ${NEW_SSH_PORT}, key only, and only ${allow_user}."
}

task_ufw() {
  export DEBIAN_FRONTEND=noninteractive
  run apt-get install -y -qq ufw

  run ufw --force reset
  run ufw default deny incoming
  run ufw default allow outgoing

  # Open the port of SSH before the firewall starts.
  run ufw limit "${NEW_SSH_PORT:-${SSH_PORT}}/tcp"
  if [[ -n "${NEW_SSH_PORT}" && "${NEW_SSH_PORT}" != "${SSH_PORT}" ]]; then
    # Keep the old port open. The operator deletes it after the test.
    run ufw limit "${SSH_PORT}/tcp"
  fi

  local port
  for port in ${EXTRA_PORTS}; do
    [[ "${port}" =~ ^[0-9]+(/(tcp|udp))?$ ]] || die "The port ${port} is not valid."
    run ufw allow "${port}"
  done

  run ufw --force enable
  record "OK   ufw: the firewall blocks each port that is not in the list."
}

task_fail2ban() {
  export DEBIAN_FRONTEND=noninteractive
  run apt-get install -y -qq fail2ban

  local ignore="127.0.0.1/8 ::1"
  [[ -n "${TRUSTED_IP}" ]] && ignore+=" ${TRUSTED_IP}"

  cat > /etc/fail2ban/jail.local <<EOF
# vps-harden.sh wrote this file.
[DEFAULT]
# The journal holds the log. A new Debian and a new Ubuntu keep no auth.log.
backend = systemd
ignoreip = ${ignore}
bantime = 1h
findtime = 10m
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = ${NEW_SSH_PORT:-${SSH_PORT}}
mode = aggressive
EOF

  run systemctl enable --now fail2ban
  run systemctl restart fail2ban
  record "OK   fail2ban: the jail for SSH bans an address after 5 failures."
}

task_crowdsec() {
  export DEBIAN_FRONTEND=noninteractive

  if ! command -v cscli > /dev/null 2>&1; then
    run apt-get install -y -qq curl gnupg
    # The repository of CrowdSec is not in Debian. This script adds it.
    log "RUN: the install script of the repository of CrowdSec"
    if ! curl -fsSL https://install.crowdsec.net | bash >> "$LOG_FILE" 2>&1; then
      die "The script cannot add the repository of CrowdSec.

Read ${LOG_FILE}."
    fi
    run apt-get update -qq
    run apt-get install -y -qq crowdsec
  fi

  # The bouncer blocks the address. CrowdSec alone only makes a decision.
  run apt-get install -y -qq crowdsec-firewall-bouncer-iptables

  if [[ -n "${TRUSTED_IP}" ]]; then
    install -d -m 755 /etc/crowdsec/parsers/s02-enrich
    cat > /etc/crowdsec/parsers/s02-enrich/trusted-ip.yaml <<EOF
# vps-harden.sh wrote this file. CrowdSec does not ban this address.
name: local/trusted-ip
description: "Do not ban the address of the operator"
whitelist:
  reason: "the address of the operator"
  ip:
    - "${TRUSTED_IP}"
EOF
  fi

  run systemctl enable --now crowdsec
  run systemctl restart crowdsec
  run systemctl enable --now crowdsec-firewall-bouncer
  record "OK   crowdsec: the agent and the bouncer run."
}

task_sysctl() {
  cat > "${SYSCTL_FILE}" <<'EOF'
# vps-harden.sh wrote this file.

# The network
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0

# The kernel
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
EOF

  # A container has no permission for some keys. Do not stop the script.
  if ! sysctl --system >> "$LOG_FILE" 2>&1; then
    record "WARN sysctl: the kernel refused one key or more. Read the log."
    return 0
  fi
  record "OK   sysctl: the kernel uses the protected values."
}

# ---------------------------------------------------------------------------
# The end
# ---------------------------------------------------------------------------

show_results() {
  local port="${NEW_SSH_PORT:-${SSH_PORT}}"
  local user="${ADMIN_USER:-<your user>}"

  tui --title "The result" --msgbox \
"${RESULTS}
WARNING: keep this session open.

Open a second terminal and test the new session now:

  ssh -p ${port} ${user}@<the address of the host>

The test failed? Use this session to correct the host.
The test passed? Delete the old port from UFW:

  ufw delete limit ${SSH_PORT}/tcp

The log is ${LOG_FILE}." 26 76
}

main() {
  relaunch_from_file "$@"
  trap 'restore_terminal; rm -f "${VPS_HARDEN_TMP:-}"' EXIT
  require_root
  require_apt
  require_whiptail

  touch "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  log "=== The script started ==="

  detect_session
  show_welcome
  choose_tasks
  ask_admin_user
  ask_ssh_port
  ask_extra_ports
  ask_trusted_ip
  confirm_start

  # The order is important. The user and the firewall come before SSH.
  has_task updates  && task_updates
  has_task user     && task_user
  has_task ufw      && task_ufw
  has_task ssh      && task_ssh
  has_task fail2ban && task_fail2ban
  has_task crowdsec && task_crowdsec
  has_task sysctl   && task_sysctl

  log "=== The script is complete ==="
  show_results
}

# Caution: keep the call and the exit on one line. See attach_terminal.
main "$@"; exit $?
