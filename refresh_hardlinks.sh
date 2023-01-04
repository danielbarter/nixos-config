rm /etc/nixos/host_specific_config_kanshi
rm /etc/nixos/host-specific-configuration.nix
rm /etc/nixos/host-specific-variables.nix

ln /etc/nixos/host-specific/$(hostname)/config_kanshi /etc/nixos/host_specific_config_kanshi
ln /etc/nixos/host-specific/$(hostname)/configuration.nix /etc/nixos/host-specific-configuration.nix
ln /etc/nixos/host-specific/$(hostname)/variables.nix /etc/nixos/host-specific-variables.nix
