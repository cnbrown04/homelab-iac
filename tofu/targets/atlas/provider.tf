# The endpoint is the tailnet address of atlas. The pipeline joins the tailnet
# with --accept-dns=false, so it cannot use a MagicDNS name. Public DNS also
# sends *.vnet.buildwithcaleb.com to hermes, so a name is not safe here.
variable "proxmox_endpoint" {
  description = "The URL of the Proxmox API of atlas."
  type        = string
  default     = "https://100.64.0.3:8006/"
}

# The token comes from PROXMOX_VE_API_TOKEN. See scripts/tofu-env.sh.
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  # Proxmox uses a self-signed certificate. The tailnet encrypts the traffic.
  insecure = true
}
