variable "node_name" {
  description = "The Proxmox node that runs the container."
  type        = string
}

variable "vm_id" {
  description = "The container ID."
  type        = number
}

variable "hostname" {
  description = "The host name of the container."
  type        = string
}

variable "description" {
  description = "The notes of the container in the Proxmox UI."
  type        = string
  default     = ""
}

# Proxmox makes each tag lowercase. An uppercase tag shows a change in each plan.
variable "tags" {
  description = "The tags of the container, in lowercase."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for tag in var.tags : tag == lower(tag)])
    error_message = "Use lowercase tags. Proxmox makes each tag lowercase."
  }
}

variable "template_file_id" {
  description = "The OS template, for example local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst."
  type        = string
}

variable "os_type" {
  description = "The OS type, for example debian, ubuntu, or alpine."
  type        = string
  default     = "unmanaged"
}

variable "unprivileged" {
  description = "Run the container as unprivileged. Only root@pam can make a privileged container."
  type        = bool
  default     = true
}

# nesting is the only feature flag that the API token can set. The other flags
# need root@pam.
variable "nesting" {
  description = "Allow nested containers. Newer distributions need it for systemd."
  type        = bool
  default     = true
}

variable "started" {
  description = "Keep the container running."
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start the container when the node starts."
  type        = bool
  default     = true
}

variable "cpu_cores" {
  description = "The number of CPU cores."
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "The memory in MiB."
  type        = number
  default     = 512
}

variable "swap_mb" {
  description = "The swap in MiB."
  type        = number
  default     = 512
}

variable "disk" {
  description = "The root file system. The size is in GiB."
  type = object({
    datastore_id = string
    size         = number
  })
}

variable "network_interfaces" {
  description = "The network interfaces. ipv4 is \"dhcp\" or an address with a prefix, for example 10.0.1.50/24."
  type = list(object({
    name         = optional(string, "eth0")
    bridge       = string
    vlan_id      = optional(number)
    mac_address  = optional(string)
    firewall     = optional(bool, false)
    ipv4         = optional(string, "dhcp")
    ipv4_gateway = optional(string)
  }))
}

variable "dns_servers" {
  description = "The DNS servers. Empty uses the DNS settings of the node."
  type        = list(string)
  default     = []
}

variable "ssh_keys" {
  description = "The SSH public keys of root."
  type        = list(string)
  default     = []
}

# A bind mount of a host path needs root@pam, so the volume is a storage ID.
variable "mount_points" {
  description = "Extra volumes. volume is a storage ID, for example local-lvm. The size is in GiB."
  type = list(object({
    volume = string
    path   = string
    size   = number
    backup = optional(bool, true)
  }))
  default = []
}
