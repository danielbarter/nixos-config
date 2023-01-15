# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let

  pkgsEmacsOverlay =  import <nixpkgs> {

    # overlay for cutting edge emacs
    config = config.nixpkgs.config;
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/800685a0ad5dfa94d6e3fffb5ffa1a208ad8c76a.tar.gz;
      }))
    ];
  };

in
{
  imports =
    [
      # include hardware specific configuration
      ./host-specific-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # dnssec randomly failing sometimes
  # with DNSSEC validation failed: no-signature
  services.resolved.dnssec = "false";

  # more reliable replacement for nscd
  services.nscd.enableNsncd = true;

  # enable systemd networking for all hosts
  # actual networkd config is host specific
  systemd.network.enable = true;

  # better networkd wait-online defaults for PCs
  # man systemd-networkd-wait-online 8
  systemd.network.wait-online.anyInterface = true;
  systemd.network.wait-online.timeout = 0;

  # give wireless cards time to turn on
  systemd.services.iwd.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

  networking = {
    # disable various default nixos networking components
    dhcpcd.enable = false;
    firewall.enable = false;
    useDHCP = false;

    useNetworkd = true;
    wireless.iwd = {
      enable = true;
    };

    # these get put into /etc/resolved.conf
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

   };

    # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # packages from overlays and local nixpkgs
    (pkgsEmacsOverlay.emacsGit.override {
      withPgtk = true;
    })

    # cmake autocomplete and emacs mode. Remove cmake binary so it
    # doesn't interfere with local environments
    ( cmake.overrideAttrs (finalAttrs: previousAttrs: { postInstall = "rm $out/bin/*";}))
    iw                  # linux tool for managing wireless networks
    tmux                # terminal multiplexer
    gnupg
    git
    vim
    stdman              # c++ stdlib man pages
    man-pages           # linux programmers man pages
    man-pages-posix     # posix man pages
    file
    strace
    pciutils            # lspci
    wget
    htop
    aspell
    aspellDicts.en
    (pass.withExtensions (exts: [exts.pass-otp]))
    python3
    nodejs
    nmap
    zip
    unzip
    radare2
    fzf                       # fuzzy searcher
    zbar                      # QRcode reader
    direnv
  ];

  documentation = {
    dev.enable = true;
    enable = true;
    man.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  programs.ssh.extraConfig = builtins.readFile ./dotfiles/ssh/config;


  # allow processes to persist after logout
  services.logind.killUserProcesses = false;
  system.activationScripts = {

    # equivalent to loginctl enable-linger danielbarter
    # which doesn't like nixos filesystem flags
    enableLingering = ''
      # remove all existing lingering users
      rm -r /var/lib/systemd/linger
      mkdir /var/lib/systemd/linger
      # enable for danielbarter
      touch /var/lib/systemd/linger/danielbarter
    '';

    homeSetup = ''
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
  };

  # enable gpg
  programs.gnupg.agent.enable = true;

  users.users = {
    annasavage = {
      isNormalUser = true;
      extraGroups = [ "libvirtd" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOFQPx3v0jpbhPbeLwjzbrdVXJQjba7vB22RCJ8NUBfiZ9RDtL/buxD95+lUQewnC5GmHfbiUuaRExODeYAjBcX0Yqf5WlrqAAcuLKFm1D1gr2gP9+SFYdtG7iQUAVPptEgGhgfm0PGDDj3bu+2bKAlYW6B8hhN8aOoJ8UD6t6JEv1UZq64v1acvcNv3BQ+S0/vQI0W48AYknSj2j1JrqKDzxSPXpzLiy8iSLEAq0lcFsb6wPnZvyzt87Wp+jRd+NPCYzER+DLYI+U0LmZQg4H03qKC+2ZVFzyeiB8uG9X+4LLBUoSE9eMIb8h0jJ5/3BgWE83P5pJgLxgn4vEw6NtulzhxUyFOmvYGiayEbwHyflAYBGVNcUZlPTef+qVI/JTvLf327JQKNBgm6mkzgiSpU3wAZmyu/XhYWaXlPWYVs/ItkiTujcnP32oYbke66u70nRNky3fRhG6zCcOLGyS+Bil8OWxDTM/oKMEDEMbg7O4uVlQYgydPoh/YqqPFnc= savagea@pyxis" ];
  };

    danielbarter = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "adbusers" "libvirtd"];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./secrets/ssh/id_rsa.pub)
      ];
    };
  };
}
