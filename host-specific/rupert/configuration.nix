{pkgs, ...}:

{
  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nixos/secrets/binary-cache/cache-priv-key.pem";
  };

  systemd.network = {
    networks = {
      "40-wlan0" = {
        matchConfig = {
          Name = "wlan0";
        };

        networkConfig = {
          DHCP = "no";
          Address = "192.168.1.10/24";
        };

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 1024;}; }
        ];
      };

      # configure ethernet interface on laptop so we can connect if wireless goes down
      # ip link set <eth-interface> up
      # ip addr add 192.168.2.9/24 dev <eth-interface>
      "40-enp37s0" = {
        matchConfig = {
          Name = "enp37s0";
        };

        networkConfig = {
          DHCP = "no";
          Address = " 192.168.2.10/24";
        };
      };
    };
  };

  boot.kernelModules = [ "kvm-amd" "vfio-pci" ];

  # load vfio drivers for the nvidia pci devices
  boot.initrd.preDeviceCommands = ''
  DEVS="0000:10:00.0 0000:10:00.1"
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
    "nouveau"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia"
    "xpad"
    "btusb"
    "btrtl"
    "btbcm"
    "btintel"
    "bluetooth" ];


  services.logind = {
    killUserProcesses = false;
    extraConfig = ''
      HandlePowerKey=ignore
      HandlePowerKeyLongPress=poweroff
    '';
  };

}
