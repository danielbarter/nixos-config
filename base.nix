{ config, pkgs, flake-outputs-args, flake, system,  ... }:

{
  nix.settings.experimental-features = "nix-command flakes";
  # use our flake input for resolving <nixpkgs>
  nix = {

    nixPath = [ "nixpkgs=${flake-outputs-args.nixpkgs.outPath}" ];

    # wipe the default flake reg, and set it to be our system nixpkgs
    extraOptions = let
      emptyFlakeRegistry = pkgs.writeText "flake-registry.json"
        (builtins.toJSON { flakes = []; version = 2; });
      in
      ''
        flake-registry = ${emptyFlakeRegistry};
    '';

  };

  nix.registry.nixpkgs.flake = flake-outputs-args.nixpkgs;

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
    git-lfs
    file
    strace
    pciutils            # lspci
    usbutils            # lsusb
    htop
    python3
    nodejs
    nmap
    zip
    unzip
    radare2
    fzf                 # fuzzy searcher
    direnv

    flake.packages."${system}".emacs
    aspell
    aspellDicts.en
    cmake               # cmake autocomplete and emacs mode.

    (pass.withExtensions (exts: [exts.pass-otp]))
    zbar # QRcode reader

    stdman              # c++ stdlib man pages
    man-pages           # linux programmers man pages
    man-pages-posix     # posix man pages

  ];

  documentation = {
    dev.enable = true;
    enable = true;
    man.enable = true;
  };


  # enable gpg
  programs.gnupg.agent.enable = true;


  # RealtimeKit is a D-Bus system service that changes the scheduling
  # policy of user processes/threads to SCHED_RR (i.e. realtime scheduling
  # mode) on request. It is intended to be used as a secure mechanism to
  # allow real-time scheduling to be used by normal user processes.
  security.rtkit.enable = true;
  services.dbus.enable = true;


  # allow processes to persist after logout
  services.logind.killUserProcesses = false;

}
