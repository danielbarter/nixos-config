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


  systemd.network = {
    networks = {
      "40-wlan0" = {
        matchConfig = {
          Name = "wlan0";
        };

        networkConfig = {
          DHCP = "no";
        };

        addresses = [
          { addressConfig = { Address = "192.168.1.13/24"; RouteMetric = 1024;}; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 1024;}; }
        ];
      };

      "40-enp88s0" = {
        matchConfig = {
          Name = "enp88s0";
        };

        networkConfig = {
          DHCP = "no";
        };

        addresses = [
          { addressConfig = { Address = "192.168.1.12/24"; RouteMetric = 512;}; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 512;}; }
        ];
      };

    };
  };



  # these get put into /etc/hosts
  networking = {

    hostName = "punky";

    hosts = {
      "192.168.1.1" = [ "asusmain" ];
      "192.168.1.2" = [ "asusaux" ];
      "192.168.1.10" = [ "rupert" ];
      "192.168.1.11" = [ "rupertwireless" ];
      "192.168.1.12" = [ "punky" ];
      "192.168.1.13" = [ "punkywireless" ];
    };

    # DNS used by resolved. resolvectl status
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
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
