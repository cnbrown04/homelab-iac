# The Mitogen strategy. mise installs Mitogen in the environment of
# ansible-core (see mise.toml), so this file gives Ansible the same path to
# the plugin on each machine and in the pipeline. See ansible.cfg.
from ansible_mitogen.plugins.strategy.mitogen_linear import StrategyModule  # noqa: F401
