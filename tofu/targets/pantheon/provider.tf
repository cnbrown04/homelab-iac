# The endpoint is the tailnet address of gaia. Each node of the cluster serves
# the API for the whole cluster. If gaia is down, set TF_VAR_proxmox_endpoint to
# the address of a different node, for example https://100.64.0.2:8006/.
# The pipeline joins the tailnet
# with --accept-dns=false, so it cannot use a MagicDNS name. Public DNS also
# sends *.vnet.buildwithcaleb.com to hermes, so a name is not safe here.
variable "proxmox_endpoint" {
  description = "The URL of the Proxmox API of the pantheon cluster."
  type        = string
  default     = "https://100.64.0.5:8006/"
}

# The token comes from PROXMOX_VE_API_TOKEN. See scripts/tofu-env.sh.
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  # Proxmox uses a self-signed certificate. The tailnet encrypts the traffic.
  insecure = true
}
