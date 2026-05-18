locals {
  network_bridge = "vmbr0"
  template_id    = 9000 # cloud-init template vmid
  ssh_user       = "shabba"
  storage        = "local-btrfs"
  target_node    = "pve2"

  target_servers = {
    target-1 = {
      machine_type = "ubuntu-server"
      target_name  = "nginx"
    }
    target-2 = {
      machine_type = "ubuntu-server"
      target_name  = "wordpress"
    }
    target-3 = {
      machine_type = "ubuntu-server"
      target_name  = "smb"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm_instance" {
  for_each = local.target_servers

  name      = each.value.target_name
  node_name = local.target_node
  started   = true
  on_boot   = true

  clone {
    vm_id        = local.template_id
    full         = true
    datastore_id = local.storage
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 2000
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = local.storage
    interface    = "scsi0"
    size         = 32
    iothread     = true
  }

  network_device {
    bridge   = local.network_bridge
    model    = "virtio"
    firewall = false
  }

  initialization {
    datastore_id = local.storage

    user_account {
      username = local.ssh_user
      password = var.vm_password
      keys     = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

output "vm_ips" {
  value = {
    for k, vm in proxmox_virtual_environment_vm.vm_instance :
    k => vm.ipv4_addresses
  }
}
