{ config, pkgs, nixpkgs,  ... }:

{
  nix.settings.experimental-features = "nix-command flakes";
  # use our flake input for resolving <nixpkgs>
  nix = {

    nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];

    # set the global flake registry
    extraOptions = let
      emptyFlakeRegistry = pkgs.writeText "flake-registry.json"
        (builtins.toJSON { flakes = []; version = 2; });
      in
      ''
        flake-registry = ${emptyFlakeRegistry};
    '';

  };

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
    binutils            # objdump, readelf and c++filt
    tmux                # terminal multiplexer
    git
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
