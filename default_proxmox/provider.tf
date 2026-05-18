//criando terraform block e o provider block
terraform {
  required_version = ">=1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.66.0"
    }
  }
}
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true
}


