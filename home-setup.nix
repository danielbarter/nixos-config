{ config, pkgs, ... }:
{
  system.activationScripts.homeSetup = ''
      # symlink emacs and vim config into home
      ln -sf /etc/nixos/dotfiles/emacs/emacs.el /home/danielbarter/.emacs.el
      ln -sf /etc/nixos/dotfiles/vim/vimrc /home/danielbarter/.vimrc

      # symlink shell config files into home
      ln -sf /etc/nixos/dotfiles/shell/alacritty.yml /home/danielbarter/.alacritty.yml
      ln -sf /etc/nixos/dotfiles/shell/bashrc /home/danielbarter/.bashrc
      ln -sf /etc/nixos/dotfiles/shell/bash_profile /home/danielbarter/.bash_profile
      ln -sf /etc/nixos/dotfiles/shell/tmux.conf /home/danielbarter/.tmux.conf

      # git config
      ln -sf /etc/nixos/dotfiles/git/gitconfig /home/danielbarter/.gitconfig

      # sway config
      ln -sf /etc/nixos/dotfiles/sway/config /home/danielbarter/.config/sway/config

      # installing mako config so we can let it be managed by dbus activation
      mkdir -p /home/danielbarter/.config/mako
      ln -sf /etc/nixos/dotfiles/sway/config_mako /home/danielbarter/.config/mako/config
    '';
}