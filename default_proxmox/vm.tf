resource "proxmox_virtual_environment_vm" "vm" {
  name      = "terraform-test"
  node_name = local.target_node
  started   = true
  on_boot   = true

  agent {
    enabled = true
  }

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
    dedicated = 2048
  }
  disk {
    datastore_id = local.storage
    interface    = "scsi0"
    size         = 32
  }

  network_device {
    bridge = local.network_bridge
    model  = "virtio"
  }
  //cloud init aqui
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
