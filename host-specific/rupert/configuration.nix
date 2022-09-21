{pkgs, ...}:

{


  networking = {

    defaultGateway = "192.168.1.1";

    interfaces."wlan0" = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.2";
          prefixLength = 24;
        }
      ];
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
