output "vm_id" {
  description = "The VMID."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "ipv4_addresses" {
  description = "The IPv4 addresses that the guest agent reports."
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}
