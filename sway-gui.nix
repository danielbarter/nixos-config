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
      pkgs.noto-fonts-color-emoji
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


  environment.systemPackages = with pkgs; [
    waybar
    dracula-theme # gtk theme
    adwaita-icon-theme # default gnome icons
    nixos-icons
    swaylock
    swayidle
    grim # screenshot functionality
    slurp # screenshot functionality
    mako # FreeDesktop notifications
    libnotify # notify-send
    fuzzel
  ];

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

  # configure GTK themes
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            cursor-size = lib.gvariant.mkInt32 24;
            cursor-theme = "Dracula-cursors";
            document-font-name = "Source Sans Pro 11";
            font-name = "Source Sans Pro 11";
            gtk-theme = "Dracula";
            icon-theme = "Adwaita";
            monospace-font-name = "Source Code Pro 11";
          };

          "org/gnome/desktop/wm/preferences" = {
            titlebar-font = "Source Sans Pro 11";
          };
        };
      }
    ];
  };
}
