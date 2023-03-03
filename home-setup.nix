{ config, pkgs, ... }:
{
  system.activationScripts.homeSetup = ''
      # symlink emacs config into home
      ln -sf /etc/nixos/dotfiles/emacs/emacs.el /home/danielbarter/.emacs.el

      # symlink shell config files into home
      ln -sf /etc/nixos/dotfiles/shell/alacritty.yml /home/danielbarter/.alacritty.yml
      ln -sf /etc/nixos/dotfiles/shell/bashrc /home/danielbarter/.bashrc
      ln -sf /etc/nixos/dotfiles/shell/bash_profile /home/danielbarter/.bash_profile
      ln -sf /etc/nixos/dotfiles/shell/tmux.conf /home/danielbarter/.tmux.conf

      # git config
      ln -sf /etc/nixos/dotfiles/git/gitconfig /home/danielbarter/.gitconfig

      # sway config
      mkdir -p /home/danielbarter/.config/sway
      mkdir -p /home/danielbarter/.config/kanshi
      mkdir -p /home/danielbarter/.config/mako
      ln -sf /etc/nixos/dotfiles/sway/config /home/danielbarter/.config/sway/config
      ln -sf /etc/nixos/dotfiles/sway/config_kanshi /home/danielbarter/.config/kanshi/config
      ln -sf /etc/nixos/dotfiles/sway/config_mako /home/danielbarter/.config/mako/config
    '';
}
