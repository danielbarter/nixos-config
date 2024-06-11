{
  pkgs,
  config,
  lib,
  ...
}:
{
  environment.systemPackages =
    # if sway is enabled, we include more packages
    let sway-enabled = config.programs.sway.enable;
        iwd-enabled = config.networking.wireless.iwd.enable;
        dev-machine = true;
    in [

      pkgs.tmux # terminal multiplexer
      pkgs.git
      pkgs.file
      pkgs.htop
      pkgs.wget
      pkgs.pciutils # lspci
      pkgs.usbutils # lsusb
      pkgs.nmap

      # we use dbus-python for the sway status bar
      (if sway-enabled then (pkgs.python3.withPackages (p: [ p.dbus-python ])) else pkgs.python3)

      pkgs.zip
      pkgs.unzip
      pkgs.fzf # fuzzy searcher
      (if sway-enabled then pkgs.emacs29-pgtk else pkgs.emacs29-nox)
      pkgs.aspell
      pkgs.aspellDicts.en
      (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))

    ] ++ lib.optionals sway-enabled [

      pkgs.alacritty # gpu accelerated terminal
      pkgs.zathura # pdf viewer
      pkgs.glib # gsettings
      pkgs.dracula-theme # gtk theme
      pkgs.gnome3.adwaita-icon-theme # default gnome icons
      pkgs.swaylock
      pkgs.swayidle
      pkgs.grim # screenshot functionality
      pkgs.slurp # screenshot functionality
      pkgs.wl-clipboard
      pkgs.mako # FreeDesktop notifications
      pkgs.libnotify # notify-send
      pkgs.kanshi # sway hotplug functionality
      pkgs.bemenu

    ] ++ lib.optionals iwd-enabled [

      pkgs.iw # linux tool for managing wireless networks

    ] ++ lib.optional dev-machine [

      pkgs.binutils # objdump, readelf and c++filt
      pkgs.strace
      pkgs.radare2
      pkgs.direnv
      pkgs.gdb
      pkgs.cmake # cmake autocomplete and emacs mode.
      pkgs.man-pages # linux programmers man pages
      pkgs.man-pages-posix # posix man pages
      pkgs.pyright
      pkgs.nixd

    ];
}
