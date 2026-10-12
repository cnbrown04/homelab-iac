#!/usr/bin/env bash
# Destroys a VM of the target pantheon and makes it again from its image.
#
#   mise run rebuild -- daedalus
#
# The script:
#   1. Plans the replacement of the VM, and asks for the name of the VM.
#   2. Deletes the node in Headscale and the agent in Wazuh.
#   3. Applies the plan. The disk of the VM is deleted.
#   4. Deletes the old host key and the cached facts, and waits for cloud-init.
#   5. Runs the playbook of the VM. The first run uses the cloud-init key.
#
# The VM must have an entry in tofu/targets/pantheon/vms.tf and a playbook
# ansible/playbooks/<host>.yml. See AGENTS.md, "Lessons".

set -euo pipefail

host="${1:-}"
root="$(git rev-parse --show-toplevel)"
playbook="$root/ansible/playbooks/$host.yml"

if [[ ! "$host" =~ ^[a-z][a-z0-9-]*$ ]] || [[ ! -f "$playbook" ]] ||
  ! grep -Eq "^    $host = \{" "$root/tofu/targets/pantheon/vms.tf"; then
  echo "Give the name of a VM in tofu/targets/pantheon/vms.tf that has a playbook." >&2
  exit 1
fi

ip="$(ansible-inventory --host "$host" 2>/dev/null | jq -r '.ansible_host // empty')"
if [[ -z "$ip" ]]; then
  echo "The inventory has no ansible_host for $host." >&2
  exit 1
fi

# shellcheck source=scripts/tofu-env.sh
source "$root/scripts/tofu-env.sh" pantheon

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

address="module.vm[\"$host\"].proxmox_virtual_environment_vm.this"
tofu -chdir="$root/tofu/targets/pantheon" plan \
  -replace="$address" -target="$address" -out="$work/rebuild.tfplan"

echo
echo "WARNING: This deletes $host and its disk. Each file on the VM is lost."
read -r -p "Type the name of the VM to continue: " answer
if [[ "$answer" != "$host" ]]; then
  echo "Stopped. No change." >&2
  exit 1
fi

echo "==> Delete the node in Headscale and the agent in Wazuh"
ansible-playbook "$root/ansible/playbooks/vm_retire.yml" -e "vm=$host"

echo "==> Replace the VM"
tofu -chdir="$root/tofu/targets/pantheon" apply "$work/rebuild.tfplan"

echo "==> Delete the old host key and the cached facts"
for name in "$ip" "$host" "$host.vnet.buildwithcaleb.com"; do
  if ssh-keygen -F "$name" >/dev/null; then
    ssh-keygen -R "$name" >/dev/null
  fi
done
rm -f "$HOME/.cache/ansible/facts/homelab-iac/$host"

echo "==> Wait for SSH on $ip"
key=""
for _ in $(seq 60); do
  key="$(ssh-keyscan -T 5 -t ed25519 "$ip" 2>/dev/null | grep ed25519 || true)"
  [[ -n "$key" ]] && break
  sleep 5
done
if [[ -z "$key" ]]; then
  echo "SSH on $ip did not start in 5 minutes. Look at the console in Proxmox." >&2
  exit 1
fi
# The VM is new, so its first key is the key to trust.
echo "$key" >>"$HOME/.ssh/known_hosts"

# cloud-init gives status 2 when it completes with a warning.
echo "==> Wait for cloud-init"
ansible "$host" -m ansible.builtin.wait_for_connection -a timeout=300
ansible "$host" -m ansible.builtin.shell -a 'cloud-init status --wait >/dev/null; test $? -ne 1'

echo "==> Configure the VM"
ansible-playbook "$playbook" --diff

echo
echo "Done. Check that a second run shows no change: mise run check:$host"
