# The VMs on the pantheon cluster. To add a VM, add one entry to this map, with
# the node that runs it. Do not write a new resource block. See AGENTS.md,
# section 4, "Repository layout".
locals {
  # The settings that each VM of the typhon cluster shares. The VMs are on
  # VLAN 20, 10.0.20.0/24. See typhon-cluster/.
  typhon = {
    description       = "Talos, the typhon cluster. OpenTofu manages this VM from homelab-iac."
    bios              = "ovmf"
    machine           = "q35"
    cpu_type          = "host"
    tablet_device     = false
    agent_wait_for_ip = false
    efi_disk          = { datastore_id = "local-lvm" }
    network_devices   = [{ bridge = "vmbr0", vlan_id = 20 }]
  }

  typhon_network = {
    datastore_id = "local-lvm"
    ipv4_gateway = "10.0.20.1"
    dns_servers  = ["10.0.20.1"]
  }

  vms = {
    typhon-cp-1 = merge(local.typhon, {
      node_name      = "gaia"
      vm_id          = 501
      tags           = ["typhon", "talos", "controlplane"]
      cpu_cores      = 6
      memory_mb      = 6144
      disks          = [{ interface = "scsi0", datastore_id = "local-lvm", size = 32, import_from = proxmox_download_file.talos["gaia"].id }]
      initialization = merge(local.typhon_network, { ipv4_address = "10.0.20.11/24" })
    })
    typhon-w-1 = merge(local.typhon, {
      node_name      = "gaia"
      vm_id          = 511
      tags           = ["typhon", "talos", "worker"]
      cpu_cores      = 8
      memory_mb      = 8192
      disks          = [{ interface = "scsi0", datastore_id = "local-lvm", size = 32, import_from = proxmox_download_file.talos["gaia"].id }]
      initialization = merge(local.typhon_network, { ipv4_address = "10.0.20.21/24" })
    })
    typhon-w-2 = merge(local.typhon, {
      node_name      = "gaia"
      vm_id          = 512
      tags           = ["typhon", "talos", "worker"]
      cpu_cores      = 8
      memory_mb      = 8192
      disks          = [{ interface = "scsi0", datastore_id = "local-lvm", size = 32, import_from = proxmox_download_file.talos["gaia"].id }]
      initialization = merge(local.typhon_network, { ipv4_address = "10.0.20.22/24" })
    })
    # The iGPU of hyperion, for the transcodes of Jellyfin. Ansible creates the
    # mapping. See the role proxmox_gpu_passthrough.
    typhon-w-3 = merge(local.typhon, {
      node_name      = "hyperion"
      vm_id          = 513
      tags           = ["typhon", "talos", "worker"]
      cpu_cores      = 8
      memory_mb      = 6144
      disks          = [{ interface = "scsi0", datastore_id = "local-lvm", size = 32, import_from = proxmox_download_file.talos["hyperion"].id }]
      initialization = merge(local.typhon_network, { ipv4_address = "10.0.20.23/24" })
      pci_mappings   = [{ mapping = "hyperion-igpu" }]
    })
    typhon-w-4 = merge(local.typhon, {
      node_name      = "hyperion"
      vm_id          = 514
      tags           = ["typhon", "talos", "worker"]
      cpu_cores      = 8
      memory_mb      = 6144
      disks          = [{ interface = "scsi0", datastore_id = "local-lvm", size = 32, import_from = proxmox_download_file.talos["hyperion"].id }]
      initialization = merge(local.typhon_network, { ipv4_address = "10.0.20.24/24" })
    })

    # The SMB server. It shares /lethe/shares of gaia through virtiofs, so it
    # must run on gaia. Ansible creates the directory mapping and configures
    # the VM. See ansible/playbooks/mnemosyne.yml.
    mnemosyne = {
      node_name   = "gaia"
      vm_id       = 200
      description = "Samba, the shares in /lethe/shares. OpenTofu manages this VM from homelab-iac."
      tags        = ["samba", "debian"]
      cpu_type    = "host"
      cpu_cores   = 2
      memory_mb   = 2048
      # The image has no guest agent. Ansible installs it.
      agent_wait_for_ip = false
      disks             = [{ interface = "scsi0", datastore_id = "local-lvm", size = 16, import_from = proxmox_download_file.debian["gaia"].id }]
      network_devices   = [{ bridge = "vmbr0" }]
      initialization = {
        datastore_id = "local-lvm"
        ipv4_address = "10.0.1.16/24"
        ipv4_gateway = "10.0.1.1"
        dns_servers  = ["10.0.1.1"]
        user_account = {
          username = "iac-admin"
          keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP88BOfNMfJoF99u1UYpf3CDUGl5nv+Ovbh0B8fyaqTH"]
        }
      }
      # expose_acl passes the POSIX ACLs and the extended attributes, for the
      # macOS metadata of Samba (streams_xattr).
      virtiofs_mappings = [{ mapping = "lethe-shares", expose_acl = true }]
    }

    # The development VM of the owner. Ansible installs the tools. See
    # ansible/playbooks/daedalus.yml.
    daedalus = {
      node_name   = "tartarus"
      vm_id       = 300
      description = "Development, Ubuntu 26.04. OpenTofu manages this VM from homelab-iac."
      tags        = ["dev", "ubuntu"]
      cpu_type    = "host"
      cpu_cores   = 8
      memory_mb   = 16384
      # The image has no guest agent. Ansible installs it.
      agent_wait_for_ip = false
      disks             = [{ interface = "scsi0", datastore_id = "local-lvm", size = 64, import_from = proxmox_download_file.ubuntu["tartarus"].id }]
      network_devices   = [{ bridge = "vmbr0" }]
      initialization = {
        datastore_id = "local-lvm"
        ipv4_address = "10.0.1.17/24"
        ipv4_gateway = "10.0.1.1"
        dns_servers  = ["10.0.1.1"]
        user_account = {
          username = "iac-admin"
          keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP88BOfNMfJoF99u1UYpf3CDUGl5nv+Ovbh0B8fyaqTH"]
        }
      }
    }
  }
}

module "vm" {
  source   = "../../modules/vm"
  for_each = local.vms

  node_name         = each.value.node_name
  vm_id             = each.value.vm_id
  name              = try(each.value.name, each.key)
  description       = try(each.value.description, "")
  tags              = try(each.value.tags, [])
  bios              = try(each.value.bios, "seabios")
  machine           = try(each.value.machine, "q35")
  cpu_type          = try(each.value.cpu_type, "x86-64-v2-AES")
  cpu_cores         = try(each.value.cpu_cores, 2)
  memory_mb         = try(each.value.memory_mb, 2048)
  tablet_device     = try(each.value.tablet_device, true)
  agent_wait_for_ip = try(each.value.agent_wait_for_ip, true)
  efi_disk          = try(each.value.efi_disk, null)
  disks             = each.value.disks
  network_devices   = each.value.network_devices
  initialization    = try(each.value.initialization, null)
  pci_mappings      = try(each.value.pci_mappings, [])
  virtiofs_mappings = try(each.value.virtiofs_mappings, [])
  usb_devices       = try(each.value.usb_devices, [])
  serial_devices    = try(each.value.serial_devices, [])
}
