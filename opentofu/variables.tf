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
  default     = "hyps01"
}