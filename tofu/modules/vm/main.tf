# One Proxmox VM. A target lists its VMs as data and calls this module once for
# each VM. See AGENTS.md, section 4, "Repository layout".
resource "proxmox_virtual_environment_vm" "this" {
  node_name   = var.node_name
  vm_id       = var.vm_id
  name        = var.name
  description = var.description
  tags        = var.tags

  on_boot       = var.on_boot
  started       = var.started
  bios          = var.bios
  machine       = var.machine
  tablet_device = var.tablet_device
  boot_order    = var.boot_order

  operating_system {
    type = var.os_type
  }

  agent {
    enabled = var.agent_enabled
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  dynamic "efi_disk" {
    for_each = var.efi_disk == null ? [] : [var.efi_disk]
    content {
      datastore_id      = efi_disk.value.datastore_id
      type              = efi_disk.value.type
      file_format       = efi_disk.value.file_format
      pre_enrolled_keys = efi_disk.value.pre_enrolled_keys
    }
  }

  dynamic "disk" {
    for_each = var.disks
    content {
      interface    = disk.value.interface
      datastore_id = disk.value.datastore_id
      size         = disk.value.size
      file_format  = disk.value.file_format
      discard      = disk.value.discard
      ssd          = disk.value.ssd
      iothread     = disk.value.iothread
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
      model       = network_device.value.model
      firewall    = network_device.value.firewall
    }
  }

  dynamic "usb" {
    for_each = var.usb_devices
    content {
      host = usb.value
    }
  }

  dynamic "serial_device" {
    for_each = var.serial_devices
    content {
      device = serial_device.value
    }
  }
}
