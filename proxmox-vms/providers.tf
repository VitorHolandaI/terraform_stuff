terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
  }
}

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox endpoint, ex: https://10.66.66.19:8006/"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Token format: USER@REALM!TOKENID=UUID"
}

variable "vm_password" {
  type        = string
  sensitive   = true
  description = "Cloud-init password for the VM user"
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent    = true
    username = "root"
  }
}
