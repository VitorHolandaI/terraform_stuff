locals {
  network_bridge = "vmbr0"
  ssh_user       = "shabba"
  storage        = "local-btrfs"
  target_node    = "pve2"
  os_template    = "local-btrfs:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

  lxc_targets = {
    ct-1 = {
      hostname = "lxc-nginx"
      cores    = 1
      memory   = 512
      disk     = 8
    }
    ct-2 = {
      hostname = "lxc-wordpress"
      cores    = 2
      memory   = 1024
      disk     = 10
    }
    ct-3 = {
      hostname = "lxc-smb"
      cores    = 1
      memory   = 512
      disk     = 8
    }
  }
}

resource "proxmox_virtual_environment_container" "ct" {
  for_each = local.lxc_targets

  node_name    = local.target_node
  unprivileged = true
  started      = true
  start_on_boot = true

  initialization {
    hostname = each.value.hostname

    user_account {
      password = var.vm_password
      keys     = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  operating_system {
    template_file_id = local.os_template
    type             = "ubuntu"
  }

  disk {
    datastore_id = local.storage
    size         = each.value.disk
  }

  network_interface {
    name   = "eth0"
    bridge = local.network_bridge
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }
}

output "lxc_info" {
  value = {
    for k, ct in proxmox_virtual_environment_container.ct :
    k => {
      vm_id    = ct.vm_id
      node     = ct.node_name
      hostname = ct.initialization[0].hostname
    }
  }
}
