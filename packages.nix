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
        gnome-enabled = config.services.desktopManager.gnome.enable;
        gui-enabled = sway-enabled || gnome-enabled;
        dev-machine = config.dev-machine;
    in with pkgs; [

      tmux # terminal multiplexer
      git
      file
      htop
      jq # json pretty print
      wget
      pciutils # lspci
      usbutils # lsusb
      nmap
      python3
      zip
      unzip
      fzf # fuzzy searcher
      helix
      aspell
      aspellDicts.en
      (pass.withExtensions (exts: [ exts.pass-otp ]))
      (python3Packages.llm.withPlugins {llm-gemini = true;})

    ] ++ lib.optionals gui-enabled [

      alacritty # gpu accelerated terminal
      zathura # pdf viewer
      wl-clipboard

    ] ++ lib.optionals dev-machine [

      binutils # objdump, readelf and c++filt
      strace
      radare2
      direnv
      gdb
      man-pages # linux programmers man pages
      man-pages-posix # posix man pages
      pyright
      nixd
      git-lfs

    ];
}
