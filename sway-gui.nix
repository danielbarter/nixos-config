{
  pkgs,
  lib,
  ...
}:
{

  # enable bluetooth
  hardware.bluetooth.enable = true;

  # make udev rules for backlight
  programs.light.enable = true;

  # firefox integration
  programs.firefox.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  fonts = {
    enableDefaultPackages = true;

    packages = [
      pkgs.source-code-pro
      pkgs.source-sans-pro
      pkgs.source-serif-pro
      pkgs.noto-fonts-emoji
    ];

    fontconfig = {
      enable = true;

      # some applications, notably alacritty, choose fonts according to
      # fontconfigs internal ordering of fonts rather than specific font
      # tags. To get the correct fonts to be rendered, we need to disable some
      # fallback fonts which nixos includes by default and fontconfig prefers
      # over user specified ones. To see this internal list, run fc-match -s

      localConf =
        let
          # function to generate patterns for fontconfig font banning
          fontBanPattern = s: ''
            <pattern>
              <patelt name="family">
                <string>${s}</string>
              </patelt>
            </pattern>
          '';

          fontsToBan = [
            "Noto Emoji"
            "DejaVu Sans"
            "FreeSans"
            "FreeMono"
            "FreeSerif"
            "DejaVu Math TeX Gyre"
            "DejaVu Sans Mono"
            "DejaVu Serif"
            "Liberation Mono"
            "Liberation Serif"
            "Liberation Sans"
            "DejaVu Serif"
            "DejaVu Serif"
            "Liberation Serif"
            "DejaVu Serif"
          ];
        in
        ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <selectfont>
              <rejectfont>
                ${lib.strings.concatStringsSep "\n" (map fontBanPattern fontsToBan)}
              </rejectfont>
            </selectfont>
          </fontconfig>
        '';

      defaultFonts = {
        monospace = [ "Source Code Pro" ];
        sansSerif = [ "Source Sans Pro" ];
        serif = [ "Source Serif Pro" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };


  environment.systemPackages = with pkgs; [
    (callPackage ./status-command.nix {})
    glib # gsettings
    dracula-theme # gtk theme
    adwaita-icon-theme # default gnome icons
    nixos-icons
    swaylock
    swayidle
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard
    mako # FreeDesktop notifications
    libnotify # notify-send
    kanshi # sway hotplug functionality
    fuzzel
  ];

  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    # clearout default packages
    extraPackages = [];

    # extra session environment variables
    # we need add gsettings-desktop-schemas to XDG_DATA_DIRS so gsettings works
    # we need to set _JAVA_AWT_WM_NONREPARENTING=1 so java GUI apps aren't broken
    extraSessionCommands =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        export _JAVA_AWT_WM_NONREPARENTING=1
        export BROWSER=firefox
      '';
  };
}
