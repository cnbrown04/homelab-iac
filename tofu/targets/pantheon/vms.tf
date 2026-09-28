# The VMs on the pantheon cluster. To add a VM, add one entry to this map, with
# the node that runs it. Do not write a new resource block. See AGENTS.md,
# section 4, "Repository layout".
locals {
  vms = {
    # example = {
    #   node_name       = "gaia"
    #   vm_id           = 200
    #   name            = "example"
    #   disks           = [{ interface = "scsi0", datastore_id = "local-lvm", size = 32 }]
    #   network_devices = [{ bridge = "vmbr0" }]
    # }
  }
}

module "vm" {
  source   = "../../modules/vm"
  for_each = local.vms

  node_name       = each.value.node_name
  vm_id           = each.value.vm_id
  name            = each.value.name
  description     = try(each.value.description, "")
  tags            = try(each.value.tags, [])
  bios            = try(each.value.bios, "seabios")
  machine         = try(each.value.machine, "q35")
  cpu_type        = try(each.value.cpu_type, "x86-64-v2-AES")
  cpu_cores       = try(each.value.cpu_cores, 2)
  memory_mb       = try(each.value.memory_mb, 2048)
  tablet_device   = try(each.value.tablet_device, true)
  efi_disk        = try(each.value.efi_disk, null)
  disks           = each.value.disks
  network_devices = each.value.network_devices
  usb_devices     = try(each.value.usb_devices, [])
  serial_devices  = try(each.value.serial_devices, [])
}
