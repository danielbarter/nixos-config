# symlink helix config into home
mkdir -p /home/danielbarter/.config
ln -sf /etc/nixos/dotfiles/helix /home/danielbarter/.config

# symlink for waybar config
ln -sf /etc/nixos/dotfiles/waybar /home/danielbarter/.config

# symlink shell config files into home
ln -sf /etc/nixos/dotfiles/shell/alacritty.toml /home/danielbarter/.alacritty.toml
ln -sf /etc/nixos/dotfiles/shell/bashrc /home/danielbarter/.bashrc
ln -sf /etc/nixos/dotfiles/shell/bash_profile /home/danielbarter/.bash_profile
ln -sf /etc/nixos/dotfiles/shell/tmux.conf /home/danielbarter/.tmux.conf

# git config
# more recent versions of nix require /etc/nixos to be marked as a safe repo for root
ln -sf /etc/nixos/dotfiles/git/gitconfig /home/danielbarter/.gitconfig
ln -sf /etc/nixos/dotfiles/git/gitconfig /root/.gitconfig


# create socket directory for ssh
mkdir -p /home/danielbarter/.ssh/sockets

# sway config
mkdir -p /home/danielbarter/.config/sway
mkdir -p /home/danielbarter/.config/mako
ln -sf /etc/nixos/dotfiles/sway/config /home/danielbarter/.config/sway/config
ln -sf /etc/nixos/dotfiles/sway/config_mako /home/danielbarter/.config/mako/config

# make sure all the above has correct user and group
chgrp -R users /home/danielbarter
chown -R danielbarter /home/danielbarter
