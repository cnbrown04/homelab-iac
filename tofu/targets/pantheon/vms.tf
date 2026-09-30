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
  usb_devices       = try(each.value.usb_devices, [])
  serial_devices    = try(each.value.serial_devices, [])
}
