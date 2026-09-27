# The bootstrap of `hermes`

This runbook protects `hermes` one time, before Ansible takes control.

Warning: this is a manual step, and it stays manual. A new host has no admin
user and no key, so the pipeline cannot reach it. After the bootstrap, Ansible
owns the users, the configuration of SSH, the firewall, the packages, and the
services. See `AGENTS.md`, decision 2.

## What you need

- The root password for `hermes` from the control panel.
- Your public SSH key, on the machine in front of you.

## The steps

1. Log in as root with the password from the panel.

   ```sh
   ssh root@192.255.220.7
   ```

2. Download the script to a file, read it, then run it. This method keeps the
   script input separate from the terminal input for whiptail.

   ```sh
    curl -fsSLo /tmp/vps-harden.sh https://raw.githubusercontent.com/cnbrown04/homelab-iac/main/scripts/vps-harden.sh
   less /tmp/vps-harden.sh
   bash /tmp/vps-harden.sh
   ```

   Caution: run `bash` as root, and not `sh`. On Debian, `sh` is dash, and dash
   does not have the syntax of bash. The script stops with a message if you use
   `sh`.

3. Answer each question. The script makes no change before the box "Confirm".

4. Warning: keep the first session open. Open a second terminal, and test the
   new user.

   ```sh
    ssh -p 22 caleb@192.255.220.7
   sudo -v
   ```

5. If you changed the SSH port, and the test passed, close the old port in the
   firewall. If the port stayed the same, keep its UFW rule.

   ```sh
   ufw delete limit <the old SSH port>/tcp
   ufw status numbered
   ```

6. The test failed? Use the first session to correct the host. The file
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

## The URL, and the trust in it

The command runs a script from the internet as root. Two facts make that safe
enough here:

- The repository is yours, and it is public. Read the script before you run it.
- The branch `main` needs a pull request, so no other person changes the script
  without a review.

Caution: the URL names the branch `main`. The content of the branch changes. Use
a tag for a host that needs the same script each time:

```sh
curl -fsSLo /tmp/vps-harden.sh https://raw.githubusercontent.com/cnbrown04/homelab-iac/v1.0.0/scripts/vps-harden.sh
bash /tmp/vps-harden.sh
```

## Notes

- The script blocks `AllowTcpForwarding`. Delete that line if you need a tunnel
  of SSH, for example `ssh -L`.
- The script adds the repository of CrowdSec, because Debian has no package for
  it. The command is `curl -fsSL https://install.crowdsec.net | bash`. Read the
  script first if your policy needs it.
- Fail2ban and CrowdSec do the same job in two ways. Fail2ban reads the log of
  this host. CrowdSec also uses the list of addresses from the community. Both
  is acceptable, and each one uses a different action.
- Whiptail needs an interactive terminal. The script sends the menu and keyboard
  to `/dev/tty`, so a pipe from `curl` does not take keyboard input.
- The script needs a `TERM` value that supports a text menu. It stops with an
  error if no interactive terminal exists or `TERM` is empty or `dumb`.
- The script does not open the ports for Headscale. Task C1 in `docs/todo.md`
  gives the port.
