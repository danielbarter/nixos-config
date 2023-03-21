{config, pkgs, ...}:
{

  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nixos/secrets/binary-cache/cache-priv-key.pem";
  };

  # serve DNS stub on local network
  services.resolved.extraConfig = ''
       DNSStubListenerExtra=192.168.1.12
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
      "30-enp88s0" = {
        matchConfig = {
          Name = "enp88s0";
        };

        networkConfig = {
          Bond = "bond0";
          PrimarySlave = "true";
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
    };
  };

  networking = {

    hostName = "punky";

    # these get put into /etc/hosts
    hosts = {
      "192.168.1.1" = [ "asusmain.meow" ];
      "192.168.1.2" = [ "asusaux.meow" ];
      "192.168.1.10" = [ "rupert.meow" ];
      "192.168.1.12" = [ "punky.meow" ];
    };

    # DNS used by resolved. resolvectl status
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    interfaces = {
      "bond0" = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.1.12";
            prefixLength = 24;
          }
        ];
        ipv4.routes = [
          {
            address = "192.168.1.0";
            prefixLength = 24;
            via = "192.168.1.1";
          }
        ];
      };
    };
  };


  hardware.enableRedistributableFirmware =  true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7ac43c6f-2132-4640-9f47-1b8676fbc26e";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6659-4237";
      fsType = "vfat";
    };

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
