{config, pkgs, ...}:
{

  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nixos/secrets/binary-cache/cache-priv-key.pem";
  };

  # dnssd for nix store
  environment.etc = {
    "systemd/dnssd/nix_store.dnssd".text = ''
    [Service]
    Name=nix_store
    Type=_http._tcp
    Port=5000
    '';
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
          { addressConfig = { Address = "192.168.1.12/24"; }; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; }; }
        ];
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
  };


  # punky is a build machine, and this lets us build nixos images
  # for other platforms, without needing to cross compile (which tends to be
  # pretty unreliable for full systems).
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];


  hardware.enableRedistributableFirmware =  true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/cfbddc74-a767-40f2-993d-729d1a5758b9";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/4CF2-BE53";
      fsType = "vfat";
    };

    "/home/danielbarter/ML" = {
      device = "/dev/disk/by-uuid/308bd10e-7a18-4610-8c7d-757a098ef2dc";
      fsType = "ext4";
    };
  };

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
