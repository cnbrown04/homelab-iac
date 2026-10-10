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
#
# The file name holds the version, so a new image is a new resource. So
# overwrite is false: the provider does not ask the URL for the size of the
# file at each refresh. The Image Factory took more than 2 minutes to answer.
resource "proxmox_download_file" "talos" {
  for_each = local.talos_images

  node_name    = each.key
  datastore_id = "local"
  content_type = "import"
  url          = "https://factory.talos.dev/image/${local.talos_schematics[each.value]}/${local.talos_version}/nocloud-amd64.qcow2"
  file_name    = "talos-${local.talos_version}-${each.value}-nocloud-amd64.qcow2"
  overwrite    = false
}

# The Debian cloud image of the Debian VMs. A VM reads its image only when
# OpenTofu creates it, so a new image here changes no VM. The list of images
# is at https://cloud.debian.org/images/cloud/trixie/. The file name holds the
# version, so overwrite is false, as for the Talos images.
locals {
  debian_image = "20261001-2618"
  debian_nodes = ["gaia"]
}

resource "proxmox_download_file" "debian" {
  for_each = toset(local.debian_nodes)

  node_name          = each.key
  datastore_id       = "local"
  content_type       = "import"
  url                = "https://cloud.debian.org/images/cloud/trixie/${local.debian_image}/debian-13-genericcloud-amd64-${local.debian_image}.qcow2"
  file_name          = "debian-13-genericcloud-amd64-${local.debian_image}.qcow2"
  checksum           = "f46f0671a6e5bdec5291ab8972bae2f10e5408c2f64a74078f11efc2f06a436a9d0313ed50e0472542eeabf780e9f7c792ac0a314c6c20507fcd9fd81b468c3d"
  checksum_algorithm = "sha512"
  overwrite          = false
}

# The Ubuntu cloud image of the Ubuntu VMs. A VM reads its image only when
# OpenTofu creates it, so a new image here changes no VM. The list of images
# is at https://cloud-images.ubuntu.com/releases/resolute/. The file is a qcow2
# image with the extension .img, and Proxmox needs .qcow2 for an import.
locals {
  ubuntu_image = "20260927"
  ubuntu_nodes = ["tartarus"]
}

resource "proxmox_download_file" "ubuntu" {
  for_each = toset(local.ubuntu_nodes)

  node_name          = each.key
  datastore_id       = "local"
  content_type       = "import"
  url                = "https://cloud-images.ubuntu.com/releases/resolute/release-${local.ubuntu_image}/ubuntu-26.04-server-cloudimg-amd64.img"
  file_name          = "ubuntu-26.04-server-cloudimg-amd64-${local.ubuntu_image}.qcow2"
  checksum           = "8800651811af9a85465ad1d552add729947bb16488dddb4a9b5305a3d97332b2"
  checksum_algorithm = "sha256"
  overwrite          = false
}
