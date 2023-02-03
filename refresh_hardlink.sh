# hard links become stale if upstream is updated
# symlink to .git/hooks/post-merge
ln -f /etc/nixos/host-specific/$(hostname)/configuration.nix /etc/nixos/host-specific-configuration.nix
