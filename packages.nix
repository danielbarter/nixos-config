{
  pkgs,
  config,
  lib,
  ...
}:
{

  options.dev-machine = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "flag for specifying whether to include development packages in systemPackages";
  };

  config.environment.systemPackages =
    # if sway is enabled, we include more packages
    let sway-enabled = config.programs.sway.enable;
        iwd-enabled = config.networking.wireless.iwd.enable;
        dev-machine = config.dev-machine;
    in with pkgs; [

      tmux # terminal multiplexer
      git
      file
      htop
      wget
      pciutils # lspci
      usbutils # lsusb
      nmap

      # we use dbus-python for the sway status bar
      (if sway-enabled then (python3.withPackages (p: [ p.dbus-python ])) else python3)

      zip
      unzip
      fzf # fuzzy searcher
      (if sway-enabled then emacs29-pgtk else emacs29-nox)
      aspell
      aspellDicts.en
      (pass.withExtensions (exts: [ exts.pass-otp ]))

    ] ++ lib.optionals sway-enabled [

      alacritty # gpu accelerated terminal
      zathura # pdf viewer
      glib # gsettings
      dracula-theme # gtk theme
      gnome3.adwaita-icon-theme # default gnome icons
      swaylock
      swayidle
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard
      mako # FreeDesktop notifications
      libnotify # notify-send
      kanshi # sway hotplug functionality
      bemenu

    ] ++ lib.optionals iwd-enabled [

      iw # linux tool for managing wireless networks

    ] ++ lib.optionals dev-machine [

      binutils # objdump, readelf and c++filt
      strace
      radare2
      direnv
      gdb
      cmake # cmake autocomplete and emacs mode.
      man-pages # linux programmers man pages
      man-pages-posix # posix man pages
      pyright
      nixd

    ];
}
