rm /etc/nixos/host-specific-configuration.nix
ln /etc/nixos/host-specific/$(hostname)/configuration.nix /etc/nixos/host-specific-configuration.nix
