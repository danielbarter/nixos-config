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

        gsettings set $gnome_schema gtk-theme 'SolArc-Dark'
        gsettings set $gnome_schema document-font-name "Source Sans Pro 11"
        gsettings set $gnome_schema font-name "Source Sans Pro 11"
        gsettings set $gnome_schema monospace-font-name "Source Code Pro 11"
        gsettings set $wm_schema titlebar-font "Source Sans Pro 11"
        '';
  };


  pkgsEmacsOverlay =  import <nixpkgs> {

    config = config.nixpkgs.config;
    # emacs overlay to get pureGTK emacs
    # current mainline emacs isn't wayland native
    # this is a problem if you are using multiple screens with different resolutions
    # this community overlay adds developer versions of emacs with wayland support
    # amoung other things.
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/a28b388b022a5fb6f8700ba04eb4d57d2e36abb6.tar.gz;
      }))
    ];
  };

  # local nixpkgs
  pkgsLocal = import /home/danielbarter/nixpkgs { config = config.nixpkgs.config; };

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

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

  networking = {
    hostName = hostSpecificVariables.hostName;
    useNetworkd = true;
    extraHosts = ''
    192.168.1.1 router_second_bedroom
    192.168.1.2 router_living_room
    192.168.1.3 rupert
    '';

    wireless.iwd = {
      enable = true;
    };

    # The list of nameservers.
    # It can be left empty if it is auto-detected through DHCP.
    nameservers = [ "8.8.8.8" "1.1.1.1" ];

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;

    # Open ports in the firewall.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8080 5000 ];
      allowedUDPPorts = [ 22 ];
    };
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

    (android-studio.override { tiling_wm = true;})
    jetbrains.idea-community
    godot
    iwgtk
    wirelesstools       # iwconfig
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
    firefox-wayland
    chromium
    fractal             # matrix client
    zathura
    aspell
    aspellDicts.en
    (pass.withExtensions (exts: [exts.pass-otp]))
    python3
    steam
    nmap
    zip
    unzip
    radare2
    fzf                       # fuzzy searcher
    zbar                      # QRcode reader
    glib                      # gsettings
    solarc-gtk-theme          # gtk theme
    gnome3.adwaita-icon-theme # default gnome icons
    swaylock
    swayidle
    grim                      # screenshot functionality
    slurp                     # screenshot functionality
    wl-clipboard
    mako                      # FreeDesktop notifications
    kanshi                    # sway hotplug functionality
    wf-recorder               # screen recording
    bemenu
    dfeet                     # dbus debugger
    virt-manager
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
    authorizedKeysFiles = ["/etc/nixos/secrets/ssh/id_rsa.pub"];

    # warning: make sshd ignore file permissions.
    # this is unsafe for public facing machines, but
    # annoying to work around for devices that are only
    # accesible on a local network when you are logging in
    # as users and root
    extraConfig = "StrictModes no";

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
    # gtk portal needed to make firefox happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    gtkUsePortal = true;
  };

  hardware = {
    # steam client needs 32 bit video/audio drivers to start
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
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

  # This enables “lingering” for danielbarter.
  # see man loginctl
  # see https://github.com/NixOS/nixpkgs/issues/3702
  # hopefully one day this will be a user option
  system.activationScripts = {
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

  users.users = {

    danielbarter = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "adbusers" "libvirtd"];
    };

    annasavage = {
      isNormalUser = true;
      extraGroups = [ "libvirtd" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOFQPx3v0jpbhPbeLwjzbrdVXJQjba7vB22RCJ8NUBfiZ9RDtL/buxD95+lUQewnC5GmHfbiUuaRExODeYAjBcX0Yqf5WlrqAAcuLKFm1D1gr2gP9+SFYdtG7iQUAVPptEgGhgfm0PGDDj3bu+2bKAlYW6B8hhN8aOoJ8UD6t6JEv1UZq64v1acvcNv3BQ+S0/vQI0W48AYknSj2j1JrqKDzxSPXpzLiy8iSLEAq0lcFsb6wPnZvyzt87Wp+jRd+NPCYzER+DLYI+U0LmZQg4H03qKC+2ZVFzyeiB8uG9X+4LLBUoSE9eMIb8h0jJ5/3BgWE83P5pJgLxgn4vEw6NtulzhxUyFOmvYGiayEbwHyflAYBGVNcUZlPTef+qVI/JTvLf327JQKNBgm6mkzgiSpU3wAZmyu/XhYWaXlPWYVs/ItkiTujcnP32oYbke66u70nRNky3fRhG6zCcOLGyS+Bil8OWxDTM/oKMEDEMbg7O4uVlQYgydPoh/YqqPFnc= savagea@pyxis" ];
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
