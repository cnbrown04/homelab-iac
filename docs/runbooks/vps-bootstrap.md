# The bootstrap of a VPS

This runbook protects a new VPS. Do it one time for each host, before Ansible
takes control.

Warning: this is a manual step, and it stays manual. A new host has no admin
user and no key, so the pipeline cannot reach it. After the bootstrap, Ansible
owns the users, the configuration of SSH, the firewall, the packages, and the
services. See `AGENTS.md`, decision 2.

## What you need

- The address of the host, and the password of root from the panel.
- Your public SSH key, on the machine in front of you.

## The steps

1. Log in as root with the password from the panel.

   ```sh
   ssh root@<the address of the host>
   ```

2. Copy the script to the host.

   ```sh
   scp scripts/vps-harden.sh root@<the address of the host>:/root/
   ```

3. Run the script on the host.

   ```sh
   chmod +x /root/vps-harden.sh
   /root/vps-harden.sh
   ```

4. Answer each question. The script makes no change before the box "Confirm".

5. Warning: keep the first session open. Open a second terminal, and test the
   new user.

   ```sh
   ssh -p <the port> <the admin user>@<the address of the host>
   sudo -v
   ```

6. The test passed? Close the old port in the firewall.

   ```sh
   sudo ufw delete limit 22/tcp
   sudo ufw status numbered
   ```

7. The test failed? Use the first session to correct the host. The file
   `/etc/ssh/sshd_config.d/99-hardening.conf` holds each change. Delete the file
   and run `systemctl restart ssh` to go back.

## What the script does

| Task | The result |
| --- | --- |
| `updates` | Installs the updates, and turns on `unattended-upgrades`. |
| `user` | Creates an admin user with sudo and your public key. |
| `ssh` | Stops the login of root, stops the password, and sets the port. |
| `ufw` | Blocks each port that is not in your list. |
| `fail2ban` | Bans an address after five failures at SSH. |
| `crowdsec` | Installs the agent and the bouncer for the firewall. |
| `sysctl` | Sets the protected values of the kernel. |

The script writes `/var/log/vps-harden.log`. Read the log after a failure.

## The order, and the reason for it

The script does the tasks in this order:

1. The updates.
2. The admin user and the key.
3. The firewall, with the port of SSH open.
4. The configuration of SSH.
5. Fail2ban, CrowdSec, and sysctl.

The user comes before the change to SSH. The script stops if no user has a key
in `authorized_keys`, because a change to SSH at that moment locks you out.

The firewall comes before the change to the port of SSH. The script opens the
new port first, and it keeps the old port open. Step 6 closes the old port.

The script tests the new configuration with `sshd -t` before the restart. A bad
file stops the service, and the host goes off the network.

## Notes

- The script blocks `AllowTcpForwarding`. Delete that line if you need a tunnel
  of SSH, for example `ssh -L`.
- The script adds the repository of CrowdSec, because Debian has no package for
  it. The command is `curl -fsSL https://install.crowdsec.net | bash`. Read the
  script first if your policy needs it.
- Fail2ban and CrowdSec do the same job in two ways. Fail2ban reads the log of
  this host. CrowdSec also uses the list of addresses from the community. Both
  is acceptable, and each one uses a different action.
- The script does not open the ports for Headscale. Task C1 in `docs/todo.md`
  gives the port.
