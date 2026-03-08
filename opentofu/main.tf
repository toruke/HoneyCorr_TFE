# =============================================================================
# ÉTAPE 1 — Télécharger l'image Ubuntu 24.04 sur hyps01
# =============================================================================
resource "proxmox_virtual_environment_download_file" "ubuntu_2404_image" {
  node_name    = var.proxmox_node
  content_type = "iso"
  datastore_id = "local"            # Stockage pour l'image

  url       = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name = "ubuntu-24.04-cloud.img"

  overwrite = false  # Ne re-télécharge pas si le fichier existe déjà
}

# =============================================================================
# ÉTAPE 2 — Fichier cloud-init 
# =============================================================================
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    file_name = "cloud-init-user-data.yaml"
    data      = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          lock_passwd: false
          passwd: $6$rounds=4096$saltsalt$hashedpassword
          ssh_authorized_keys:
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAngsas1Sh3MzHOfsJ6IPRRhqPgOz+lzabDxL9KfR0yL abenpro@outlook.fr
      packages:
        - qemu-guest-agent
      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
      EOF
  }
}

# =============================================================================
# ÉTAPE 3 — Création des vmbr sur proxmox
# =============================================================================

resource "proxmox_virtual_environment_network_linux_vlan" "vlan10" {
  node_name  = var.proxmox_node
  name       = "vmbr0.10"
  comment    = "VLAN 10 - Management"
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlan20" {
  node_name  = var.proxmox_node
  name       = "vmbr0.20"
  comment    = "VLAN 20 - Production"
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlan30" {
  node_name  = var.proxmox_node
  name       = "vmbr0.30"
  comment    = "VLAN 30 - Honeypot"
}


# =============================================================================
# ÉTAPE 4 — Créer le template cloud-init
# =============================================================================
resource "proxmox_virtual_environment_vm" "ubuntu_2404_template" {
  name      = "ubuntu-2404-template"
  node_name = var.proxmox_node
  vm_id     = 9000
  template  = true               # Convertit directement en template
  started   = false              # Un template ne démarre jamais

  description = "Template Ubuntu 24.04 cloud-init — géré par OpenTofu"

  # Agent QEMU (permet de récupérer l'IP automatiquement)
  agent {
    enabled = true
  }

  # CPU
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  # Mémoire
  memory {
    dedicated = 2048
  }

  # Disque — utilise l'image téléchargée à l'étape 1
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_2404_image.id
    interface    = "scsi0"
    size         = 20
    discard      = "on"
    iothread     = true
  }

  # Réseau
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Serial — obligatoire pour cloud-init
  serial_device {
    device = "socket"
  }

  # Interface cloud-init
  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # Contrôleur SCSI
  scsi_hardware = "virtio-scsi-single"
}


# =============================================================================
# ÉTAPE 5 — Créer les VM depuis le template
# =============================================================================

resource "proxmox_virtual_environment_vm" "vms" {
  for_each  = var.vms
  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  stop_on_destroy = true 

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_2404_template.vm_id
    full  = true
  }

  agent {
    enabled = true
    timeout = "5m"
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
    vlan_id = each.value.vlan_id 
  }

  initialization {
    datastore_id      = "local-lvm"
    interface         = "ide2"
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id

    dns {
      servers = ["10.1.0.254", "1.1.1.1"]
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.1.0.254"
      }
    }

    user_account {
      username = "ubuntu"
      password = "root"
      keys     = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAngsas1Sh3MzHOfsJ6IPRRhqPgOz+lzabDxL9KfR0yL abenpro@outlook.fr"
      ]
    }
  }

  scsi_hardware = "virtio-scsi-single"
}