variable "proxmox_api_url" {
  type        = string
  description = "Url da api do proxmox"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "token"
}

variable "vm_password" {
  type        = string
  sensitive   = true
  description = "Senha inicial da vm"
}

