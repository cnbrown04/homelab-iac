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

    # A new Talos VM has no agent until it gets its config. So the create
    # must not wait for the IP that the agent reports.
    dynamic "wait_for_ip" {
      for_each = var.agent_wait_for_ip ? [] : [true]
      content {
        disabled = true
      }
    }
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
      import_from  = disk.value.import_from
    }
  }

  # The cloud-init drive. Talos nocloud reads its network from it.
  dynamic "initialization" {
    for_each = var.initialization == null ? [] : [var.initialization]
    content {
      datastore_id = initialization.value.datastore_id
      type         = "nocloud"

      ip_config {
        ipv4 {
          address = initialization.value.ipv4_address
          gateway = initialization.value.ipv4_gateway
        }
      }

      dns {
        servers = initialization.value.dns_servers
      }

      # The first user of a cloud image. Ansible logs in as this user.
      dynamic "user_account" {
        for_each = initialization.value.user_account == null ? [] : [initialization.value.user_account]
        content {
          username = user_account.value.username
          keys     = user_account.value.keys
        }
      }
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

  # A PCI device through a cluster resource mapping. With a mapping, an API
  # token with Mapping.Use can attach the device. See AGENTS.md, "Lessons".
  dynamic "hostpci" {
    for_each = var.pci_mappings
    content {
      device  = "hostpci${hostpci.key}"
      mapping = hostpci.value.mapping
      pcie    = hostpci.value.pcie
      rombar  = hostpci.value.rombar
    }
  }

  # A host folder through a cluster directory mapping. With a mapping, an API
  # token with Mapping.Use can attach the folder. The guest mounts it with the
  # mapping name as the tag.
  dynamic "virtiofs" {
    for_each = var.virtiofs_mappings
    content {
      mapping    = virtiofs.value.mapping
      cache      = virtiofs.value.cache
      expose_acl = virtiofs.value.expose_acl
      # Proxmox needs the extended attributes for the ACLs. The provider
      # refuses expose_acl with expose_xattr = false, so send true or nothing.
      expose_xattr = virtiofs.value.expose_acl || virtiofs.value.expose_xattr ? true : null
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
