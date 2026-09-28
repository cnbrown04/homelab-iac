# The VMs on atlas. To add a VM, add one entry to this map. Do not write a new
# resource block. See AGENTS.md, section 4, "Repository layout".
locals {
  vms = {
    haos = {
      vm_id       = 100
      name        = "haos-18.2"
      description = "Home Assistant OS. OpenTofu manages this VM from homelab-iac."
      tags        = ["community-script"]
      bios        = "ovmf"
      machine     = "q35"
      # The VM has no cpu line, so it runs qemu64.
      cpu_type      = "qemu64"
      cpu_cores     = 2
      memory_mb     = 4096
      tablet_device = false
      efi_disk      = { datastore_id = "local-lvm" }
      disks = [
        { interface = "scsi0", datastore_id = "local-lvm", size = 32 },
      ]
      network_devices = [
        { bridge = "vmbr0", mac_address = "02:92:86:E2:D5:49" },
        { bridge = "vmbr0", mac_address = "BC:24:11:34:EE:A1", vlan_id = 10 },
      ]
      # The Zigbee or Z-Wave adapter, a CP210x.
      usb_devices    = ["10c4:ea60"]
      serial_devices = ["socket"]
    }
  }
}

module "vm" {
  source   = "../../modules/vm"
  for_each = local.vms

  node_name       = "atlas"
  vm_id           = each.value.vm_id
  name            = each.value.name
  description     = each.value.description
  tags            = each.value.tags
  bios            = each.value.bios
  machine         = each.value.machine
  cpu_type        = each.value.cpu_type
  cpu_cores       = each.value.cpu_cores
  memory_mb       = each.value.memory_mb
  tablet_device   = each.value.tablet_device
  efi_disk        = each.value.efi_disk
  disks           = each.value.disks
  network_devices = each.value.network_devices
  usb_devices     = each.value.usb_devices
  serial_devices  = each.value.serial_devices
}
