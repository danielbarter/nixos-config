{config, pkgs, ...}:
let
  libvirt-dbus = pkgs.callPackage ./libvirt-dbus.nix {};
in {
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

  services.cockpit = {
    enable = true;
    port = 80;
  };

  systemd.services.libvirtdbus = {
    after = [ "libvirtd.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      User = "libvirtdbus";
      ExecStart = "${libvirt-dbus}/bin/libvirt-dbus --system";
    };
  };

  services.dbus.packages = [
    libvirt-dbus
  ];

  environment.systemPackages = [
    libvirt-dbus
  ];


  users.users = {
    libvirtdbus = {
      isNormalUser = true;
      extraGroups = [ "libvirtd" ];
    };
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
    hostName = "rupert";
    nameservers = [ "192.168.1.12" ];
  };

  boot.kernelModules = [ "kvm-amd" "vfio-pci" ];

  # load vfio drivers for the amd gpu pci devices
  # note: if some device in an IOMMU group is passed through,
  # all devices in that group must be passed through
  boot.initrd.preDeviceCommands = ''
  DEVS="0000:12:00.0 0000:12:00.1"
  for DEV in $DEVS; do
    echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  done
  '';

  virtualisation.libvirtd = {
    enable = true;
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

  # xpad messes up usb passthrough to windows for xbox controllers, so
  # disable it.
  boot.blacklistedKernelModules = [
    "xpad"
  ];

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
