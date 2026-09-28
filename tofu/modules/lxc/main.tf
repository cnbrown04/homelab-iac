# One Proxmox container. A target lists its containers as data and calls this
# module once for each container. See AGENTS.md, section 4, "Repository layout".
resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = var.description
  tags          = var.tags
  unprivileged  = var.unprivileged
  started       = var.started
  start_on_boot = var.start_on_boot

  features {
    nesting = var.nesting
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.disk.datastore_id
    size         = var.disk.size
  }

  initialization {
    hostname = var.hostname

    dynamic "dns" {
      for_each = length(var.dns_servers) > 0 ? [1] : []
      content {
        servers = var.dns_servers
      }
    }

    dynamic "ip_config" {
      for_each = var.network_interfaces
      content {
        ipv4 {
          address = ip_config.value.ipv4
          gateway = ip_config.value.ipv4_gateway
        }
      }
    }

    dynamic "user_account" {
      for_each = length(var.ssh_keys) > 0 ? [1] : []
      content {
        keys = var.ssh_keys
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name        = network_interface.value.name
      bridge      = network_interface.value.bridge
      vlan_id     = network_interface.value.vlan_id
      mac_address = network_interface.value.mac_address
      firewall    = network_interface.value.firewall
    }
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume = mount_point.value.volume
      path   = mount_point.value.path
      size   = "${mount_point.value.size}G"
      backup = mount_point.value.backup
    }
  }
}
