{ config, pkgs, ... }:

{
  imports =
    [
      ./host-specific-configuration.nix
      ./networking.nix
      ./emacs.nix
      ./users.nix
      ./lingering.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";


  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    tmux                # terminal multiplexer
    git
    vim
    file
    strace
    pciutils            # lspci
    htop
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

  # enable gpg
  programs.gnupg.agent.enable = true;


}
