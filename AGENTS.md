# Agent rules for this repository

These rules apply to every agent and every person who writes content here.

## 1. Write in Simplified Technical English

Write all chat replies, code comments, documents, and commit messages in
ASD-STE100 Simplified Technical English. See https://www.asd-ste100.org/.

The standard has two parts: a dictionary of approved words, and 53 writing
rules. Use the rules below. They are the part of the standard that changes
the text most.

### Words

- Use one word for one meaning. Do not use a synonym later in the same
  document. If you write "delete", do not change to "remove".
- Use one part of speech for one word. "Test" is a noun or a verb, but keep
  to one use in one document.
- Use the approved word when a simple word exists: "start" and not
  "initiate", "use" and not "utilize", "before" and not "prior to".
- Keep technical names and technical verbs. "OpenTofu", "SOPS", "encrypt",
  and "provision" are correct.
- Do not use more than three nouns together. Write "the token for the API of
  Proxmox" and not "the Proxmox API token cluster".

### Sentences

- Write one instruction in one sentence.
- Keep an instruction to 20 words or less. Keep a description to 25 words
  or less.
- Use the active voice. Write "OpenTofu creates the VM" and not "the VM is
  created by OpenTofu".
- Use the imperative for an instruction. Write "Run `mise install`."
- Use the simple present or the simple past tense. Do not use the future
  tense and do not use the perfect tense.
- Do not use a verb that ends in "-ing" as the main verb.
- Keep the articles "a", "an", and "the". Do not delete them to make the
  text short.
- Write a paragraph of six sentences or less.

### Warnings and cautions

Put the warning before the instruction. Give the condition first, then the
action.

### Exceptions

These rules do not apply to:

- Command names, file paths, flags, and code.
- Output that you copy from a tool.
- Text that you quote from a third party.

## 2. Use Conventional Commits

Write every commit message in the Conventional Commits format. See
https://www.conventionalcommits.org/.

```
<type>(<scope>): <description>

<body>

<footer>
```

### Types

| Type | Use |
| --- | --- |
| `feat` | A new capability. |
| `fix` | A correction of a defect. |
| `docs` | A change to documents only. |
| `refactor` | A change that does not add a capability or correct a defect. |
| `test` | A change to tests only. |
| `ci` | A change to the GitHub Actions workflows. |
| `build` | A change to the toolchain, for example `mise.toml`. |
| `chore` | Other work, for example a version bump. |

### Scopes

Use the area of the repository as the scope: `tofu`, `ansible`, `mise`,
`ci`, `docs`, `secrets`. Use no scope if the change touches many areas.

### Rules

- Write the description in the imperative. Write "add the node" and not
  "added the node" or "adds the node".
- Start the description with a lower case letter. Do not put a full stop at
  the end.
- Keep the first line to 72 characters or less.
- Put the reason for the change in the body. The code shows what changed.
  The body must show why.
- Mark a breaking change with a `!` after the type, and add a
  `BREAKING CHANGE:` footer.

### Branches

Name a branch `<type>/<short-description>`, for example
`feat/proxmox-vm-module`. Use the same type names as the commits.

## 3. Project context

This repository deploys changes to a homelab. Every change goes through a pull
request and a GitHub Actions pipeline. Do not apply a change by hand and do not
configure a host over ad-hoc SSH after the pipeline exists.

### The hardware

- A Proxmox VE cluster of four nodes. The cluster has one API endpoint.
- One standalone Proxmox VE node. It has its own API endpoint.
- A RackNerd VPS. The panel is SolusVM.
- A DediRock VPS. The panel is WHMCS. Reviews name Virtualizor.

### Decisions

These decisions are closed. Ask the owner before you re-open one.

1. **Use OpenTofu and not Terraform.** OpenTofu encrypts the state, and the
   provider ecosystem is the same.
2. **Each tool does one job.** OpenTofu creates and changes a resource. Ansible
   configures a host that already runs. Do not create a Proxmox VM with
   Ansible. Do not manage a VPS with OpenTofu.
3. **Use a GitHub-hosted runner only.** A self-hosted runner in the homelab
   needs the homelab, but it exists to repair the homelab. Each job that needs
   the Proxmox API starts with the Tailscale GitHub Action. The action joins
   the runner to the tailnet as an ephemeral node for the length of the job.
4. **Ansible manages both VPS hosts.** No OpenTofu provider exists for SolusVM
   or for WHMCS and Virtualizor. Use plain SSH.
5. **The state is remote and encrypted.** Use an S3-compatible backend and the
   state encryption of OpenTofu.
6. **SOPS and age encrypt the secrets.** Keep the Tailscale OAuth client in a
   GitHub secret, because it has no other home.
7. **A human approves an apply.** Put a GitHub environment with a required
   reviewer in front of the apply job.

### Repository layout

Build this layout. Do not make it flat.

```text
tofu/
  modules/
    vm/              # one Proxmox VM, written one time
    lxc/             # one Proxmox container, written one time
  targets/
    pve-cluster/     # four nodes, one API endpoint, one state
    pve-standalone/  # one node, its own API endpoint, its own state
ansible/
  inventory/         # one file for each target, and both VPS hosts
  group_vars/
  roles/
  playbooks/
docs/runbooks/       # the steps that stay manual
.github/workflows/
renovate.json
```

Each folder in `tofu/targets/` is an OpenTofu root with its own state. A target
file lists its VMs and containers as data, then calls the `vm` module or the
`lxc` module. To add a server, add one entry to that list. Do not write a new
resource block.

### The toolchain

`mise.toml` holds the version of each tool. It is the only correct source for a
version. Run `mise install` to get the tools. Renovate bumps the versions. Do
not change a version by hand.

### Build order

Do these steps in order. Do not start step 5 before step 4 is complete, because
the plan job needs Tailscale to reach the Proxmox API.

1. Verify each risk in `context/handoff-original.md`. Record each answer in
   `docs/runbooks/`.
2. Scaffold the layout. Pin the tool versions. Add Renovate.
3. Set up the remote state backend, the state encryption, and SOPS with age.
4. Set up Tailscale: the account, a tag for GitHub Actions, an ACL rule for the
   Proxmox API port, and an OAuth client in a GitHub secret.
5. Write the `vm` module and the `lxc` module. Write the `pve-standalone`
   target. Import each resource that exists into the state. The step is
   complete when `tofu plan` shows no change.
6. Do step 5 again for `pve-cluster`.
7. Write the Ansible baseline for the five Proxmox nodes and the two VPS hosts.
   The step is complete when `ansible-playbook --check` shows no change.
8. Add the workflows with a matrix over the targets. Turn on the PR checks,
   then the apply job. The step is complete when a merged change applies with
   no manual step.

### Do not

- Do not add a self-hosted runner. The owner rejected it.
- Do not manage a VPS with OpenTofu.
- Do not commit a state file.
- Do not put a secret in plain text in the repository. This includes the
  commit history.
- Do not give the Tailscale tag for GitHub Actions more access than the Proxmox
  API port.

## 4. The `context/` folder

`context/` holds the context for one topic, for example the notes for a task in
progress or a document from a third party. Git ignores the folder.

- Read a file in `context/` for background.
- Do not commit a file in `context/`. Do not remove the folder from
  `.gitignore`.
- The folder is local to one machine. It does not go to another machine and it
  does not go to a new clone.
- If a fact in `context/` must last, move the fact into this file or into
  `docs/`. A file in `context/` is scratch.

`context/handoff-original.md` is the first handoff document. It holds the risks
for step 1 of the build order.
