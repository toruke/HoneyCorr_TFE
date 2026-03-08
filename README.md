# How to install the project

## prerequis

first you have to install opentofu 

for debian user : 
```bash
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method deb

# Remove the installer:
rm -f install-opentofu.sh
```

if you use somthink else go to : https://opentofu.org/docs/intro/install/deb/

## install the projet

go in your folder to install the projet and use git:
```
git clone https://codeberg.org/ben1348/HoneyCorr_TFE.git
cd HONEYCORR_TFE
```

after that créate a file terraform.tfvars where you can store your vars for your proxmox server ...