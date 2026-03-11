# 1. BLOC terraform
# Dit à OpenTofu quels plugins (providers) télécharger
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"  # Où télécharger le provider (registry.opentofu.org/bpg/proxmox)
      version = "0.98.1"      # Version à utiliser
    }
  }
}

# 2. BLOC provider
# Dit à OpenTofu comment se connecter à Proxmox
provider "proxmox" {
  endpoint  = var.proxmox_url    # URL de l'API Proxmox l'ip ici
  api_token = var.proxmox_token  # Token d'authentification
  insecure  = true               # Ignore le certificat SSL auto-signé

  ssh {
    agent    = true
    username = "root"
  }
}
