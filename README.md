# 🍯 HoneyCorr TFE

> Déploiement automatisé d'un honeypot via OpenTofu + Ansible sur Proxmox.


[![OpenTofu](https://img.shields.io/badge/OpenTofu-00C7B7?style=for-the-badge&logo=opentofu&logoColor=white)](https://opentofu.org/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white)](https://www.proxmox.com/)
[![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)](https://git-scm.com/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Licence](https://img.shields.io/badge/Licence-MIT-green?style=for-the-badge)](LICENSE)
[![Codeberg](https://img.shields.io/badge/Codeberg-2185D0?style=for-the-badge&logo=codeberg&logoColor=white)](https://codeberg.org/ben1348/HoneyCorr_TFE)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ton-utilisateur/HoneyCorr_TFE)

```
git clone → tofu apply → ansible-playbook → honeypot opérationnel
```

---

## Prérequis

- Un serveur **Proxmox** avec accès API
- **OpenTofu** installé sur votre machine (voir ci-dessous)
- Une paire de clés SSH générée sur votre poste

---

## 1. Installer OpenTofu

### Debian / Ubuntu

```bash
# Télécharger le script d'installation
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

# Donner les droits d'exécution
chmod +x install-opentofu.sh

# Lancer l'installation
./install-opentofu.sh --install-method deb

# Nettoyer
rm -f install-opentofu.sh
```

> Pour toute autre distribution, consultez la [documentation officielle](https://opentofu.org/docs/intro/install/).

---

## 2. Cloner le projet

```bash
git clone https://codeberg.org/ben1348/HoneyCorr_TFE.git
cd HoneyCorr_TFE
```

---

## 3. Configurer les variables OpenTofu

Copiez le fichier générique et remplissez-le avec vos informations :

```bash
cp opentofu/terraform.tfvars.generic opentofu/terraform.tfvars
```

Éditez ensuite `terraform.tfvars` avec les valeurs suivantes :

| Variable | Description |
|---|---|
| `proxmox_url` | URL de votre serveur Proxmox (ex: `https://10.1.0.10:8006`) |
| `proxmox_token` | Token API de votre utilisateur Proxmox |
| `proxmox_node` | Nom du nœud Proxmox cible |
| `vms` | Dictionnaire des VMs à créer (voir exemple ci-dessous) |
| `ssh_key` | Contenu de votre clé publique SSH (`~/.ssh/id_rsa.pub`) |
| `vm_user` | Nom d'utilisateur à créer sur les VMs |

### Exemple de `terraform.tfvars`

```hcl
proxmox_url   = "your url"
proxmox_token = "userproxmox@pve!yourtoken"
proxmox_node  = "yourname"

vms = {
  "honeypots10" = { vm_id = 100, ip = "10.1.10.10", gateway = "10.1.10.254", cores = 1, memory = 1024, vlan_id = 10 }
  "honeypots11" = { vm_id = 101, ip = "10.1.10.11", gateway = "10.1.10.254", cores = 1, memory = 1024, vlan_id = 10 }
  "honeypots12" = { vm_id = 102, ip = "10.1.10.12", gateway = "10.1.10.254", cores = 1, memory = 1024, vlan_id = 10 }
  "honeypots20" = { vm_id = 200, ip = "10.1.20.10", gateway = "10.1.20.254", cores = 1, memory = 1024, vlan_id = 20 }
  "honeypots30" = { vm_id = 300, ip = "10.1.30.10", gateway = "10.1.30.254", cores = 1, memory = 1024, vlan_id = 30 }
}

ssh_key = "your public key"
vm_user = "honeycorr"
```

> ⚠️ Le fichier `terraform.tfvars` est listé dans le `.gitignore` et ne sera **jamais commité**. Ne partagez jamais votre token Proxmox.

---

## 4. Déployer les VMs avec OpenTofu

```bash
cd opentofu

# Initialiser OpenTofu
tofu init

# Vérifier le plan
tofu plan

# Appliquer
tofu apply
```

---

## 5. Configurer les honeypots avec Ansible

```bash
cd ansible

# Vérifier la connectivité
ansible -i inventory/hosts.ini all -m ping

# Lancer le playbook
ansible-playbook -i inventory/hosts.ini playbooks/honeypots.yml
```

---

## Structure du projet

```
HoneyCorr_TFE/
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts.ini               # Inventaire des hôtes
│   ├── playbooks/
│   │   └── honeypots.yml           # Playbook principal
│   └── roles/
│       └── common/
│           ├── handlers/
│           │   └── main.yml
│           └── tasks/
│               └── main.yml
├── opentofu/
│   ├── templates/
│   │   └── cloud-init.yaml.tftpl   # Template cloud-init pour les VMs
│   ├── main.tf                     # Configuration principale
│   ├── providers.tf                # Déclaration du provider Proxmox
│   ├── variables.tf                # Déclaration des variables
│   ├── terraform.tfvars.generic    # Template de configuration (versionné)
│   └── terraform.tfvars            # Votre configuration (non versionné ⚠️)
├── Schema/                         # Schémas d'architecture
├── .env
├── .gitignore
├── LICENSE
└── README.md
```

---

## Licence

Ce projet est réalisé dans le cadre d'un TFE (Travail de Fin d'Études).