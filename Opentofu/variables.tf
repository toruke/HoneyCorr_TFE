variable "proxmox_url" {
  description = "URL de l'API Proxmox"
  type        = string
}

variable "proxmox_token" {
  description = "Token API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nœud Proxmox cible"
  type        = string
}

variable "vms"{
  description = "List des VMs à créer"
  type = map(object({
    vm_id    = number
    ip       = string
    cores    = number
    memory   = number
    vlan_id  = number
    gateway = string
    groupe = string
  }))
}

variable "ssh_public_key" {
  description = "Clé ssh publique"
  type = string
}

variable "ssh_private_key"{
  description = "Clé ssh privé"
  type = string
  default     = "~/.ssh/id_ed25519"
}

variable "vm_user" {
  description = "Username par défaut des VMs"
  type        = string
  default     = "debian"
}

variable "storage_vm" {
  description = "Espace de stocage pour le projet honeycorr"
  type        = string 
}

variable "storage_iso" {
  description = "Espace de stocage pour le projet honeycorr"
  type        = string 
}