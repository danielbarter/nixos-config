{ config, pkgs, ... }:

{
  imports =
    [
      ./host-specific-configuration.nix
      ./networking.nix
      ./emacs.nix
      ./users.nix
      ./lingering.nix
      ./pass.nix
      ./home-setup.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";


  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    tmux                # terminal multiplexer
    git
    vim
    file
    strace
    pciutils            # lspci
    htop
    python3
    nodejs
    nmap
    zip
    unzip
    radare2
    fzf                 # fuzzy searcher
    direnv
  ];

  # RealtimeKit is a D-Bus system service that changes the scheduling
  # policy of user processes/threads to SCHED_RR (i.e. realtime scheduling
  # mode) on request. It is intended to be used as a secure mechanism to
  # allow real-time scheduling to be used by normal user processes.
  security.rtkit.enable = true;
  services.dbus.enable = true;

}
