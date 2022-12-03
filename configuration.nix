# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # set host specific variables. Looks like this:
  # {pkgs, ...}:
  #
  # {
  #   hostName = ...;
  #   initialVersion = ...;
  #   packages = ...;
  # }
  #
  hostSpecificVariables = import ./host-specific-variables.nix {inherit pkgs;};


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


  pkgsEmacsOverlay =  import <nixpkgs> {

    # overlay for cutting edge emacs
    config = config.nixpkgs.config;
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/d39052346c5fbb66c8210c263b0c8db8afd9fed2.tar.gz;
      }))
    ];
  };

  # local nixpkgs
  pkgsLocal = import /home/danielbarter/nixpkgs { config = config.nixpkgs.config; };

in
{
  imports =
    [
      # include hardware specific configuration
      ./host-specific-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # dnssec randomly failing sometimes
  # with DNSSEC validation failed: no-signature
  services.resolved.dnssec = "false";

  # more reliable replacement for nscd
  services.nscd.enableNsncd = true;

  # enable systemd networking for all hosts
  # actual networkd config is host specific
  systemd.network.enable = true;

  # better networkd wait-online defaults for PCs
  # man systemd-networkd-wait-online 8
  systemd.network.wait-online.anyInterface = true;
  systemd.network.wait-online.timeout = 0;

  # give wireless cards time to turn on
  systemd.services.iwd.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

  networking = {
    hostName = hostSpecificVariables.hostName;

    # disable various default nixos networking components
    dhcpcd.enable = false;
    firewall.enable = false;
    useDHCP = false;

    useNetworkd = true;
    wireless.iwd = {
      enable = true;
    };

    # these get put into /etc/resolved.conf
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

   };

    # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # packages from overlays and local nixpkgs
    pkgsEmacsOverlay.emacsPgtk

    # cmake autocomplete and emacs mode. Remove cmake binary so it
    # doesn't interfere with local environments
    ( cmake.overrideAttrs (finalAttrs: previousAttrs: { postInstall = "rm $out/bin/*";}))
    iwgtk
    iw                  # linux tool for managing wireless networks
    nix-index           # nix-locate
    alacritty           # gpu accelerated terminal
    pulseaudioFull      # pactl
    light               # control backlight
    pavucontrol         # pulseaudio control volume
    helvum              # pipewire patchbay
    gammastep           # redshift
    gnupg
    git
    vim
    sway
    dbus-sway-environment
    configure-gtk
    wayland
    stdman              # c++ stdlib man pages
    man-pages           # linux programmers man pages
    man-pages-posix     # posix man pages
    xkeyboard_config    # useful man pages for sway
    file
    strace
    pueue               # task management
    pciutils            # lspci
    wget
    htop
    firefox
    chromium
    zathura
    aspell
    aspellDicts.en
    (pass.withExtensions (exts: [exts.pass-otp]))
    python3
    nmap
    zip
    unzip
    radare2
    fzf                       # fuzzy searcher
    zbar                      # QRcode reader
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
    direnv
  ] ++ hostSpecificVariables.packages;

  # make udev rules for backlight
  programs.light.enable = true;

  documentation = {
    dev.enable = true;
    enable = true;
    man.enable = true;
  };

  environment.etc = {
    "sway/config".source = "/etc/nixos/dotfiles/sway/config";
    "gitconfig".source = "/etc/nixos/dotfiles/git/gitconfig";
  };


  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

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

  # cool simple batch system
  systemd.user.services.pueued = {
    description = "pueued daemon";
    bindsTo = [ "default.target" ];
    wants = [ "default.target" ];
    after = [ "default.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = '' ${pkgs.pueue}/bin/pueued'';
    };
  };


  # gammastep systemd service
  systemd.user.services.gammastep = {
    description = "gammastep daemon";
    serviceConfig = {
      Type = "simple";
      ExecStart = '' ${pkgs.gammastep}/bin/gammastep -O 4000 '';
    };
  };



  # allow processes to persist after logout
  services.logind.killUserProcesses = false;
  system.activationScripts = {

    # equivalent to loginctl enable-linger danielbarter
    # which doesn't like nixos filesystem flags
    enableLingering = ''
      # remove all existing lingering users
      rm -r /var/lib/systemd/linger
      mkdir /var/lib/systemd/linger
      # enable for danielbarter
      touch /var/lib/systemd/linger/danielbarter
    '';
  };

  # enable gpg
  programs.gnupg.agent.enable = true;

  # enable android debug bridge
  programs.adb.enable = true;

  virtualisation.docker.enable = true;

  users.users = {

    danielbarter = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "adbusers" "libvirtd" "docker"];
      openssh.authorizedKeys.keyFiles = [
        "/etc/nixos/secrets/ssh/id_rsa.pub"
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = hostSpecificVariables.initialVersion;  # Did you read the comment?

}
