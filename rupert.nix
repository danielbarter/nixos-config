{config, pkgs, ...}:
let
  python-env = pkgs.python310.withPackages ( p: [ p.libvirt p.gunicorn ]);
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


  systemd.services.windows-control-server-serve = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ]; # require service at boot time

    serviceConfig = {
      WorkingDirectory="/etc/nixos/utils/windows_control_server/frontend";
      ExecStart = "${python-env}/bin/python -m http.server 80";
    };

  };

  systemd.services.windows-control-server-api = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ]; # require service at boot time

    serviceConfig = {
      WorkingDirectory="/etc/nixos/utils/windows_control_server";
      ExecStart = "${python-env}/bin/gunicorn -w 1 -b 0.0.0.0:10001 windows_control_server:app";
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
    };
  };

  networking = {
    hostName = "rupert";
    nameservers = [ "192.168.1.12" ];
    interfaces = {
      "bond0" = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.1.10";
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

  boot.kernelModules = [ "kvm-amd" "vfio-pci" ];

  # load vfio drivers for the amd gpu pci devices
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


  # xpad messes up usb passthrough to windows for xbox controllers, so
  # disable it. Also disable all the bluetooth driver loading so we
  # can pass through to windows.
  boot.blacklistedKernelModules = [
    "xpad"
    "btusb"
    "btrtl"
    "btbcm"
    "btintel"
    "bluetooth" ];


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
