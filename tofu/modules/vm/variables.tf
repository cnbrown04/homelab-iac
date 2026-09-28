variable "node_name" {
  description = "The Proxmox node that runs the VM."
  type        = string
}

variable "vm_id" {
  description = "The VMID."
  type        = number
}

variable "name" {
  description = "The name of the VM."
  type        = string
}

variable "description" {
  description = "The notes of the VM in the Proxmox UI."
  type        = string
  default     = ""
}

variable "tags" {
  description = "The tags of the VM."
  type        = list(string)
  default     = []
}

variable "on_boot" {
  description = "Start the VM when the node starts."
  type        = bool
  default     = true
}

variable "started" {
  description = "Keep the VM running."
  type        = bool
  default     = true
}

variable "bios" {
  description = "The firmware: seabios or ovmf."
  type        = string
  default     = "seabios"
}

variable "machine" {
  description = "The QEMU machine type, for example q35."
  type        = string
  default     = "q35"
}

variable "os_type" {
  description = "The guest OS type, for example l26 for Linux."
  type        = string
  default     = "l26"
}

variable "cpu_cores" {
  description = "The number of CPU cores."
  type        = number
  default     = 2
}

# A VM with no cpu line in its configuration runs qemu64. Set this value to
# qemu64 for such a VM, or the next apply changes the CPU type.
variable "cpu_type" {
  description = "The CPU type."
  type        = string
  default     = "x86-64-v2-AES"
}

variable "memory_mb" {
  description = "The memory in MiB."
  type        = number
  default     = 2048
}

variable "agent_enabled" {
  description = "Use the QEMU guest agent."
  type        = bool
  default     = true
}

variable "tablet_device" {
  description = "Add a USB tablet for the pointer in the console."
  type        = bool
  default     = true
}

variable "boot_order" {
  description = "The boot devices, in order."
  type        = list(string)
  default     = ["scsi0"]
}

variable "disks" {
  description = "The disks. The size is in GiB."
  type = list(object({
    interface    = string
    datastore_id = string
    size         = number
    file_format  = optional(string, "raw")
    discard      = optional(string, "on")
    ssd          = optional(bool, true)
    iothread     = optional(bool, false)
  }))
}

variable "efi_disk" {
  description = "The EFI disk. Set it when bios is ovmf."
  type = object({
    datastore_id      = string
    type              = optional(string, "4m")
    file_format       = optional(string, "raw")
    pre_enrolled_keys = optional(bool, false)
  })
  default = null
}

variable "network_devices" {
  description = "The network devices, in order: net0, net1, and so on."
  type = list(object({
    bridge      = string
    mac_address = optional(string)
    vlan_id     = optional(number, 0)
    model       = optional(string, "virtio")
    firewall    = optional(bool, false)
  }))
}

variable "usb_devices" {
  description = "USB devices of the host, as vendor:product. Only root@pam can change them."
  type        = list(string)
  default     = []
}

variable "serial_devices" {
  description = "Serial devices, for example socket."
  type        = list(string)
  default     = []
}
