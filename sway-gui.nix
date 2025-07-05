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
        # make alacritty use noto color emoji as second fallback for monospace
        monospace = [ "Source Code Pro" "Noto Color Emoji" ];
        sansSerif = [ "Source Sans Pro" ];
        serif = [ "Source Serif Pro" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };



  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    # clearout default packages
    extraPackages = [];

    extraSessionCommands =
      ''
        export BROWSER=firefox
      '';
  };
}
