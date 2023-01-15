{ config, pkgs, lib, ... }:

let
  # bash script to let dbus know about important env variables and propogate them to
  # relevent services
  # run at the end of sway config
  # see https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
  dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
  systemctl --user stop pipewire wireplumber pipewire-pulse xdg-desktop-portal xdg-desktop-portal-wlr
  systemctl --user start pipewire wireplumber pipewire-pulse xdg-desktop-portal xdg-desktop-portal-wlr
      '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # also some gtk fonts not being set by nixos config
  configure-gtk = pkgs.writeTextFile {
      name = "configure-gtk";
      destination = "/bin/configure-gtk";
      executable = true;
      text = let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        wm_schema=org.gnome.desktop.wm.preferences

        gsettings set $gnome_schema gtk-theme 'Dracula'
        gsettings set $gnome_schema icon-theme 'Dracula'
        gsettings set $gnome_schema document-font-name "Source Sans Pro 11"
        gsettings set $gnome_schema font-name "Source Sans Pro 11"
        gsettings set $gnome_schema monospace-font-name "Source Code Pro 11"
        gsettings set $wm_schema titlebar-font "Source Sans Pro 11"
        '';
  };
in
{
  environment.systemPackages = with pkgs; [
    iwgtk
    alacritty                 # gpu accelerated terminal
    pavucontrol               # pulseaudio control volume
    gammastep                 # redshift
    dbus-sway-environment
    configure-gtk
    wayland
    xkeyboard_config          # useful man pages for sway
    firefox
    chromium
    zathura
    glib                      # gsettings
    dracula-theme             # gtk theme
    gnome3.adwaita-icon-theme # default gnome icons
    swaylock
    swayidle
    grim                      # screenshot functionality
    slurp                     # screenshot functionality
    wl-clipboard
    mako                      # FreeDesktop notifications
    libnotify                 # notify-send
    kanshi                    # sway hotplug functionality
    wf-recorder               # screen recording
    bemenu
    virt-manager
    steam
  ];

  # make udev rules for backlight
  programs.light.enable = true;

  # RealtimeKit is a D-Bus system service that changes the scheduling
  # policy of user processes/threads to SCHED_RR (i.e. realtime scheduling
  # mode) on request. It is intended to be used as a secure mechanism to
  # allow real-time scheduling to be used by normal user processes.
  security.rtkit.enable = true;
  services.pipewire = {

    config.pipewire = {
      "log.level" = 4;  # https://docs.pipewire.org/page_daemon.html
    };
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };


  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  services.dbus = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  hardware = {
    # steam client needs 32 bit video/audio drivers to start
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];

    # lets steam interact with hardware
    steam-hardware.enable = true;
  };

  # build everything with pulseaudio support
  nixpkgs.config.pulseaudio = true;

  fonts = {
    enableDefaultFonts = true;

    fonts = with pkgs; [
      source-code-pro
      source-sans-pro
      source-serif-pro
      noto-fonts-emoji
    ];

    fontconfig = {
      enable = true;

      # some applications, notably alacritty, choose fonts according to
      # fontconfigs internal ordering of fonts rather than specific font
      # tags. To get the correct fonts to be rendered, we need to disable some
      # fallback fonts which nixos includes by default and fontconfig prefers
      # over user specified ones. To see this internal list, run fc-match -s


      localConf = let
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
        ]; in
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
        serif     = [ "Source Serif Pro" ];
        emoji     = [ "Noto Color Emoji" ];
      };
    };

  };

  # make sure pixbuf has access to an svg loader
  services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # useful program for printing keypresses
  programs.wshowkeys.enable = true;

  # gammastep systemd service
  systemd.user.services.gammastep = {
    description = "gammastep daemon";
    serviceConfig = {
      Type = "simple";
      ExecStart = '' ${pkgs.gammastep}/bin/gammastep -O 4000 '';
    };
  };


}

