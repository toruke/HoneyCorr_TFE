# =============================================================================
# ÉTAPE 1 — Télécharger l'image Ubuntu 24.04 sur hyps01
# =============================================================================
resource "proxmox_virtual_environment_download_file" "ubuntu_2404_image" {
  node_name    = var.proxmox_node   # hyps01
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
# ÉTAPE 3 — Créer le template cloud-init
# =============================================================================
resource "proxmox_virtual_environment_vm" "ubuntu_2404_template" {
  name      = "ubuntu-2404-template"
  node_name = var.proxmox_node   # hyps01
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
# ÉTAPE 4 — Créer la VM vm-test-01 depuis le template
# =============================================================================
resource "proxmox_virtual_environment_vm" "vm_test_01" {
  name      = "vm-test-01"
  node_name = var.proxmox_node
  vm_id     = 100
  started   = true

  description = "VM de test — gérée par OpenTofu"

  # Cloner depuis le template 9000
  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_2404_template.vm_id
    full  = true  # Clone complet (pas de lien avec le template)
  }

  agent {
    enabled = true
    timeout = "5m"
  }

  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 1024  # 1 Go RAM
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
  }

  # Cloud-init — configuration automatique au premier boot
  initialization {
    datastore_id = "local-lvm"
    
    # Installation de l'agent QEMU
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id
    # DNS
    dns {
      servers  = ["10.1.0.254", "1.1.1.1"]
    }

    # IP statique
    ip_config {
      ipv4 {
        address = "10.1.0.50/24"
        gateway = "10.1.0.254"
      }
    }

    # Utilisateur et clé SSH
#    user_account {
#      username = "ubuntu"
#      keys     = [
#      password = "root"
#        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAngsas1Sh3MzHOfsJ6IPRRhqPgOz+lzabDxL9KfR0yL abenpro@outlook.fr"
#      ]
#    }
  }

  scsi_hardware = "virtio-scsi-single"
}
