cd /etc/nixos

sudo chattr -R -i /var/lib/machines/nixos
sudo machinectl remove nixos
nix build .#nixosConfigurations.container.config.system.build.tarball
sudo machinectl import-tar result/tarball/nixos-system-x86_64-linux.tar.xz nixos
