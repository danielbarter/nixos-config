# NixOS system configuration

Configuration is parameterized over the files in `host-specific`. They need to be symlinked into the root of this repo:

```
ln -s /etc/nixos/host-specific/<hostname>/configuration.nix /etc/nixos/host-specific-configuration.nix
ln -s /etc/nixos/host-specific/<hostname>/variables.nix /etc/nixos/host-specific-variables.nix
ln -s /etc/nixos/host-specific/<hostname>/config_kanshi.nix /etc/nixos/host_specific_config_kanshi
```

