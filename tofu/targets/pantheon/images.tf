# The Talos images of the typhon cluster, from the Image Factory. Each node
# that runs a Talos VM needs its own copy, because the storage is local.
locals {
  # renovate: datasource=github-releases depName=siderolabs/talos
  talos_version = "v1.14.2"

  # The Image Factory names a set of extensions by a hash, the schematic ID.
  # Create a new ID with a POST of the schematic to
  # https://factory.talos.dev/schematics.
  talos_schematics = {
    # siderolabs/qemu-guest-agent
    base = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
    # siderolabs/i915, siderolabs/intel-ucode, siderolabs/qemu-guest-agent
    intel_gpu = "95d432d6bb450a67e801a6ae77c96a67e38820b62ba4159ae7e997e1695207f7"
  }

  # The schematic of each node that runs a Talos VM.
  talos_images = {
    gaia     = "base"
    hyperion = "intel_gpu"
  }
}

# A VM reads its image only when OpenTofu creates it. talosctl upgrades a
# running node, so a new image here changes no VM.
resource "proxmox_download_file" "talos" {
  for_each = local.talos_images

  node_name    = each.key
  datastore_id = "local"
  content_type = "import"
  url          = "https://factory.talos.dev/image/${local.talos_schematics[each.value]}/${local.talos_version}/nocloud-amd64.qcow2"
  file_name    = "talos-${local.talos_version}-${each.value}-nocloud-amd64.qcow2"
}
