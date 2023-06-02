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

  networking = {
    hostName = "jasper";
    # nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

  systemd.network.networks = {
    "40-wlan0" = {
      matchConfig = {
        Name = "wlan0";
      };

      networkConfig = {
        DHCP = "yes";
        IgnoreCarrierLoss = "3s"; # needed to roam between different access points with same SSID on LAN
      };
    };
  };

  services.resolved.extraConfig = ''
       DNSStubListener=no
  '';


  services.logind.lidSwitch = "suspend";
  services.logind = {
    extraConfig = "HandlePowerKey=suspend";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelModules = [ "kvm-intel" ];


  hardware.enableRedistributableFirmware =  true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/784c98bf-646b-4f21-a176-9067b5a059f3";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8F55-8AC0";
      fsType = "vfat";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor =  "powersave";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.11";  # Did you read the comment?
}
