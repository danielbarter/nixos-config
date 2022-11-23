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

Setup nixos configuration.
Configuration is parameterized over the files in `host-specific`. They need to be symlinked into the root of this repo:
```
$ nixos-generate-config --root /mnt
$ mv /mnt/etc/nixos /tmp/nixos
$ git clone https://github.com/danielbarter/nixos-config /mnt/etc/nixos
$ cp /tmp/nixos/hardware-configuration.nix /mnt/etc/nixos

$ ln -s /mnt/etc/nixos/host-specific/<hostname>/configuration.nix /mnt/etc/nixos/host-specific-configuration.nix
$ ln -s /mnt/etc/nixos/host-specific/<hostname>/variables.nix /mnt/etc/nixos/host-specific-variables.nix
$ ln -s /mnt/etc/nixos/host-specific/<hostname>/config_kanshi.nix /mnt/etc/nixos/host_specific_config_kanshi

# set hostname and initial version in host-specific-variables.nix.

# Generate gpg keys and ssh keys. They should be stored as follows:
# /mnt/etc/nixos/secrets/
#                      ├── gpg
#                      │   ├── privkey.asc
#                      │   └── public.asc
#                      └── ssh
#                          ├── id_rsa
#                          ├── id_rsa.pub

$ mkdir -p /mnt/etc/nixos/secrets/gpg
$ mkdir -p /mnt/etc/nixos/secrets/ssh
$ cd /mnt/etc/nixos/secrets/gpg
$ gpg --full-generate-key
$ gpg --output public.asc --armor --export <email>
$ gpg --output privkey.asc --armor --export-secret-key <email>
$ ssh-keygen -o
```



```
$ nixos-install
```



