# NixOS system configuration


### Installation checklist

Connect to the internet:
```
$ iwctl
# station <interface> get-networks
# station <interface> connect <SSID>
```

Partition block device:
```
$ parted <block_device>
# mklabel gpt
# mkpart primary 512MB 100%
# mkpart ESP fat32 1MB 512MB
# set 2 esp on
```

Format the partitions:
```
$ mkfs.ext4 -L nixos <block_device>1
$ mkfs.fat -F 32 -n boot <block_device>2
 ```

Mount filesystem:
```
$ mount /dev/disk/by-label/nixos /mnt
$ mkdir -p /mnt/boot
$ mount /dev/disk/by-label/boot /mnt/boot
```

Install Nixos
```
# this generates a minimal configuration which we use to bootstrap
# up to the full configuration style used in this repo
$ nixos-generate-config --root /mnt
$ nixos-install
```

Secrets
```
# Secrets are stored as follows:
# /mnt/etc/nixos/secrets/
# ├── binary-cache
# │   ├── cache-priv-key.pem
# ├── gpg
# │   ├── privkey.asc
# └── ssh
#     ├── id_rsa
# make sure all the leaves have permissions 600, with appropriate user and group
# corresponding public keys are stored as follows:
# /mnt/etc/nixos/public/
# ├── binary-cache
# │   ├── cache-pub-key.pem
# ├── gpg
# │   ├── public.asc
# └── ssh
#     ├── id_rsa.pub
# secrets are generated as follows:
$ gpg --full-generate-key
$ gpg --output public.asc --armor --export <email>
$ gpg --output privkey.asc --armor --export-secret-key <email>
$ ssh-keygen
```
