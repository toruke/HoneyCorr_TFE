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
  }))
}