# Runs scripts/opkssh-login.sh one time at the start of each run of
# ansible-playbook and ansible, before Ansible connects to a host. The script
# logs in to Pocket ID only when the opkssh key is missing or older than 23
# hours. ansible.cfg enables this plugin.
from __future__ import annotations

import os
import subprocess
from pathlib import Path

from ansible import context
from ansible.plugins.callback import CallbackBase

DOCUMENTATION = """
name: opkssh_login
type: notification
short_description: Log in with opkssh before Ansible connects
description:
  - Runs scripts/opkssh-login.sh one time for each run.
  - Skips the pipeline, which uses its own key, and the runs that do not
    connect.
"""

# ansible/plugins/callback/opkssh_login.py -> the root of the repository.
ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "scripts" / "opkssh-login.sh"

# These options of ansible-playbook do not connect to a host.
NO_CONNECTION_OPTIONS = ("syntax", "listhosts", "listtasks", "listtags")


class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "notification"
    CALLBACK_NAME = "opkssh_login"
    CALLBACK_NEEDS_ENABLED = True

    def __init__(self):
        super().__init__()
        self._done = False

    def _login(self):
        if self._done:
            return
        self._done = True

        # The pipeline logs in with its own key. See .github/actions/ansible-access.
        if os.environ.get("GITHUB_ACTIONS") == "true":
            return
        if any(context.CLIARGS.get(option) for option in NO_CONNECTION_OPTIONS):
            return

        # Ansible changes the state of its own stdout, and a write of the
        # script to it fails. So the script writes to the terminal. With no
        # terminal, Ansible prints the output after the script ends.
        try:
            terminal = open("/dev/tty", "w")
        except OSError:
            terminal = None
        try:
            result = subprocess.run(
                [str(SCRIPT)],
                cwd=ROOT,
                env={**os.environ, "QUIET": "1"},
                stdin=subprocess.DEVNULL,
                stdout=terminal or subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                check=False,
            )
        finally:
            if terminal:
                terminal.close()
        if result.stdout:
            self._display.display(result.stdout.rstrip())

        # Ansible turns an exception of a callback into a warning, and the run
        # goes on. SystemExit stops the run before it connects.
        if result.returncode != 0:
            self._display.error(
                "The opkssh login failed, so Ansible cannot connect. "
                "Run mise run login, and look at its output."
            )
            raise SystemExit(1)

    # A playbook run starts here.
    def v2_playbook_on_start(self, playbook):
        self._login()

    # An ad hoc run of ansible has no playbook, only a play.
    def v2_playbook_on_play_start(self, play):
        self._login()
