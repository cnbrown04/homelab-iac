# The containers on the node atlas. To add a container, add one entry to
# this map. Do not write a new resource block.
locals {
  containers = {
    # example = {
    #   vm_id              = 300
    #   hostname           = "example"
    #   template_file_id   = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    #   os_type            = "debian"
    #   disk               = { datastore_id = "local-lvm", size = 8 }
    #   network_interfaces = [{ bridge = "vmbr0" }]
    # }
  }
}

module "lxc" {
  source   = "../../modules/lxc"
  for_each = local.containers

  node_name          = "atlas"
  vm_id              = each.value.vm_id
  hostname           = each.value.hostname
  description        = try(each.value.description, "")
  tags               = try(each.value.tags, [])
  template_file_id   = each.value.template_file_id
  os_type            = try(each.value.os_type, "unmanaged")
  cpu_cores          = try(each.value.cpu_cores, 1)
  memory_mb          = try(each.value.memory_mb, 512)
  swap_mb            = try(each.value.swap_mb, 512)
  disk               = each.value.disk
  network_interfaces = each.value.network_interfaces
  dns_servers        = try(each.value.dns_servers, [])
  ssh_keys           = try(each.value.ssh_keys, [])
  mount_points       = try(each.value.mount_points, [])
}
