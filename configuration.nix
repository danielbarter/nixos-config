# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # currently just a set of network wpa passwords
  secrets = import ./secrets/secrets.nix;

  # set host specific variables. Looks like this:
  # {pkgs, ...}:
  #
  # {
  #   hostName = ...;
  #   wirelessInterface = ...;
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
  systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
  systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      '';
};

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


  networking = {
    hostName = hostSpecificVariables.hostName;

    wireless = {
      enable = true;  # Enables wireless support via wpa_supplicant.

      # make sure wpa_supplicant attempts to use the correct interface
      interfaces = [ hostSpecificVariables.wirelessInterface ];


      networks = secrets.networks;
    };

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;

    # this is a desktop computer configuration
    # we are always going to be using DHCP on some wireless interface
    # that interface changes from machine to machine
    interfaces.${hostSpecificVariables.wirelessInterface}.useDHCP = true;


    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Open ports in the firewall.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8080 ];
      allowedUDPPorts = [ 22 ];
    };

  };

  # needed for users to use non standard caches
  nix.settings.trusted-users = ["danielbarter" "root"];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty           # gpu accelerated terminal
    pavucontrol         # pulseaudio control volume
    helvum              # pipewire patchbay
    gammastep           # redshift
    gnupg
    git
    sway
    dbus-sway-environment
    wayland
    manpages
    file
    strace
    pueue               # task management
    pciutils            # lspci
    man-pages
    man-pages-posix
    wget
    htop
    firefox-wayland
    zathura
    aspell
    aspellDicts.en
    (pass.withExtensions (exts: [exts.pass-otp]))
    python38
    nix-serve
    steam
    nmap
    zip
    unzip
    radare2
    fzf                # fuzzy searcher
    zbar               # QRcode reader
  ] ++ hostSpecificVariables.packages;


  documentation.dev.enable = true;

  environment.etc = {
    "sway/config".source = "/etc/nixos/dotfiles/sway/config";
    "gitconfig".source = "/etc/nixos/dotfiles/git/gitconfig";
  };


  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
    authorizedKeysFiles = ["/etc/nixos/secrets/ssh/id_rsa.pub"];
  };

  services.logind = {
    killUserProcesses = false;
    extraConfig = "HandlePowerKey=suspend";
  };


  # RealtimeKit is a D-Bus system service that changes the scheduling
  # policy of user processes/threads to SCHED_RR (i.e. realtime scheduling
  # mode) on request. It is intended to be used as a secure mechanism to
  # allow real-time scheduling to be used by normal user processes.
  security.rtkit.enable = true;
  services.pipewire = {
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
  services.dbus.enable = true;
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

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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
      # bump NotoColorEmoji up in the fc-match -s list
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <alias binding="weak">
            <family>monospace</family>
            <prefer>
              <family>emoji</family>
            </prefer>
          </alias>
          <alias binding="weak">
            <family>sans-serif</family>
            <prefer>
              <family>emoji</family>
            </prefer>
          </alias>
          <alias binding="weak">
            <family>serif</family>
            <prefer>
              <family>emoji</family>
            </prefer>
          </alias>
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


  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
        swaylock
        swayidle
        grim         # screenshot functionality
        slurp        # screenshot functionality
        wl-clipboard
        # make sure the default gnome icons are avaliable
        # to gtk applications
        gnome3.adwaita-icon-theme
      ];
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


  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = hostSpecificVariables.initialVersion;  # Did you read the comment?

}
