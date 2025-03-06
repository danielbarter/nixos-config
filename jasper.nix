{
  config,
  pkgs,
  lib,
  ...
}:

{

  dev-machine = true;

  nix = {
    settings = {
      substituters = [ "http://punky.meow:5000" ];

      trusted-public-keys = [ (builtins.readFile ./public/binary-cache/cache-pub-key.pem) ];
    };
  };

  networking = {
    hostName = "jasper";
    # nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

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

      "30-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          PrivateKeyFile = "/etc/nixos/secrets/wireguard/${config.networking.hostName}";
          ListenPort = 51820;
        };
        wireguardPeers = ./wireguard-peers.nix; 
      };
    };

    networks = {
      "30-enp88s0" = {
        matchConfig = {
          Name = "enp88s0";
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
            Address = "192.168.1.13/24";
          }
        ];

        routes = [
          {
            Gateway = "192.168.1.1";
          }
        ];
      };

      "30-wg0" = {
        matchConfig.Name = "wg0";
        address = ["192.168.2.13/24"];
      };
    };
  };

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  services.logind = {
    extraConfig = "HandlePowerKey=suspend";
  };

  programs.adb.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3e74cb7c-1f46-4a90-af40-04ac22c54d2e";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A65D-C287";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
