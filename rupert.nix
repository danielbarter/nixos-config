{config, pkgs, ...}:
{
  nix = {
    settings = {
      substituters = [
        "http://punky.meow:5000"
      ];

      trusted-public-keys = [
        (builtins.readFile ./public/binary-cache/cache-pub-key.pem)
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    steam
    firefox
  ];

  # enable bluetooth
  hardware.bluetooth.enable = true;

  # gnome
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  hardware = {
    # steam client needs 32 bit video/audio drivers to start
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];

    # lets steam interact with hardware
    steam-hardware.enable = true;
  };

  # kernel module for switch pro controller
  boot.kernelModules = [ "hid-nintendo" ];



  services.resolved.extraConfig = ''
       DNSStubListener=no
  '';

  # bonding ethernet and wireless (with ethernet as primary)
  systemd.network = {
    netdevs = {
      "30-bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };

        bondConfig = {
          Mode = "active-backup";
          PrimaryReselectPolicy = "always";
          MIIMonitorSec = "1s";
        };
      };
    };

    networks = {
      "30-enp37s0" = {
        matchConfig = {
          Name = "enp37s0";
        };

        networkConfig = {
          Bond = "bond0";
          PrimarySlave = true;
        };
      };

      "30-wlan0" = {
        matchConfig = {
          Name = "wlan0";
        };

        networkConfig = {
          Bond = "bond0";
        };
      };

      "30-bond0" = {
        matchConfig = {
          Name = "bond0";
        };

        networkConfig = {
          DHCP = "no";
        };

        addresses = [
          { addressConfig = { Address = "192.168.1.10/24"; }; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; }; }
        ];
      };
    };
  };

  networking = {
    networkmanager.enable = false;
    hostName = "rupert";
    nameservers = [ "192.168.1.12" ];
  };


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f3dcb6ca-b39f-4c0a-86a7-72f9f331a1e0";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6146-A760";
      fsType = "vfat";
    };

  fileSystems."/home/danielbarter/windows" =
    { device = "/dev/disk/by-label/windows";
      fsType = "ext4";
    };



  services.logind = {
    extraConfig = ''
      HandlePowerKey=ignore
      HandlePowerKeyLongPress=poweroff
    '';
  };


  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];

  swapDevices = [ ];

  hardware.enableRedistributableFirmware = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09";  # Did you read the comment?



}
