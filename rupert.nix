{ pkgs, ... }:
{
  nix = {
    settings = {
      substituters = [ "http://punky.meow:5000" ];

      trusted-public-keys = [ (builtins.readFile ./public/binary-cache/cache-pub-key.pem) ];
    };
  };

  programs.firefox.enable = true;

  programs.steam.enable = true;

  # controls the max number of memory mapped areas a process can have
  # modern games have been hitting the default limit which is low
  # 512 * 1024 = 524288
  boot.kernel.sysctl = {
    "vm.max_map_count" = 524288;
  };

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
          MulticastDNS = "yes";
        };

        addresses = [
          {
            Address = "192.168.1.10/24";
          }
        ];

        routes = [
          {
            Gateway = "192.168.1.1";
          }
        ];
      };
    };
  };

  networking = {
    hostName = "rupert";
    nameservers = [ "192.168.1.12" ];
    networkmanager.enable = false;
  };

  services.avahi.enable = false;

  services.gnome.core-utilities.enable = true;

  boot.kernelModules = [ "hid-nintendo" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f3dcb6ca-b39f-4c0a-86a7-72f9f331a1e0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6146-A760";
    fsType = "vfat";
  };

  fileSystems."/home/danielbarter/windows" = {
    device = "/dev/disk/by-label/windows";
    fsType = "ext4";
  };

  services.logind = {
    extraConfig = ''
      HandlePowerKey=ignore
      HandlePowerKeyLongPress=poweroff
    '';
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];

  swapDevices = [ ];


  # enabling gnome
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  hardware.bluetooth.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
