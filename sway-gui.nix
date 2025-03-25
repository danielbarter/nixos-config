{
  pkgs,
  lib,
  ...
}:
{


  # make udev rules for backlight
  programs.light.enable = true;

  # firefox integration
  programs.firefox.enable = true;

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

    enableDefaultPackages = false;

    packages = [
      pkgs.source-code-pro
      pkgs.source-sans-pro
      pkgs.source-serif-pro
      pkgs.noto-fonts-emoji
      pkgs.font-awesome
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Source Code Pro" ];
        sansSerif = [ "Source Sans Pro" ];
        serif = [ "Source Serif Pro" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };


  environment.systemPackages = with pkgs; [
    waybar
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
