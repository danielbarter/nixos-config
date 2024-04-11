{lib, config, pkgs, flake-outputs-args, flake,  ... }:

{

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
    usbutils            # lsusb
    htop
    python3
    nmap
    zip
    unzip
    radare2
    fzf                 # fuzzy searcher
    direnv
    gdb

    emacs29-pgtk
    aspell
    aspellDicts.en
    cmake               # cmake autocomplete and emacs mode.

    (pass.withExtensions (exts: [exts.pass-otp]))

    man-pages           # linux programmers man pages
    man-pages-posix     # posix man pages

  ];

  documentation = {
    dev.enable = true;
    enable = true;
    man.enable = true;
  };

  # RealtimeKit is a D-Bus system service that changes the scheduling
  # policy of user processes/threads to SCHED_RR (i.e. realtime scheduling
  # mode) on request. It is intended to be used as a secure mechanism to
  # allow real-time scheduling to be used by normal user processes.
  security.rtkit.enable = true;
  services.dbus.enable = true;

  # enable gpg
  programs.gnupg.agent = {
    enable = true;

    # soon, will become
    # pinentryPackage = pkgs.pinentry-curses;
    pinentryFlavor = "curses";
  };

  # allow processes to persist after logout
  services.logind.killUserProcesses = false;

  systemd.coredump = {
    enable = true;

    # we store core dumps in the journal, because then they are retained
    # for crashes which happen in sandboxes e.g nix build actions
    extraConfig = "Storage=journal";
  };

}
