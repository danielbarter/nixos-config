{
  lib,
  config,
  pkgs,
  flake-outputs-args,
  flake,
  gui,
  ...
}:

{

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    grub.enable = false;
    efi.canTouchEfiVariables = true;
  };

  # use systemd in stage 1. Easier to diagnose issues when they arise
  boot.initrd.systemd.enable = true;

  hardware.enableAllFirmware = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    binutils # objdump, readelf and c++filt
    tmux # terminal multiplexer
    git
    file
    strace
    pciutils # lspci
    usbutils # lsusb
    htop
    # we use dbus-python for the sway status bar
    (if gui then (python3.withPackages (p: [ p.dbus-python ])) else python3)
    nmap
    zip
    unzip
    radare2
    fzf # fuzzy searcher
    direnv
    gdb
    (if gui then emacs29-pgtk else emacs29-nox)
    aspell
    aspellDicts.en
    cmake # cmake autocomplete and emacs mode.

    (pass.withExtensions (exts: [ exts.pass-otp ]))

    man-pages # linux programmers man pages
    man-pages-posix # posix man pages
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
    pinentryPackage = pkgs.pinentry-curses;
  };

  # allow processes to persist after logout
  services.logind.killUserProcesses = false;
}
