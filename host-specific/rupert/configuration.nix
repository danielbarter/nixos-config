{pkgs, ...}:

{
  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nixos/secrets/binary-cache/cache-priv-key.pem";
  };

  # these get put into /etc/hosts
  networking.hosts = {
    "192.168.1.1" = [ "asusmain" ];
    "192.168.1.2" = [ "asusaux" ];
    "192.168.1.10" = [ "rupert" ];
    "192.168.1.11" = [ "rupertwlan" ];
  };

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
          { addressConfig = { Address = "192.168.1.11/24"; RouteMetric = 1024;}; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 1024;}; }
        ];
      };

      "40-enp37s0" = {
        matchConfig = {
          Name = "enp37s0";
        };

        networkConfig = {
          DHCP = "no";
        };

        addresses = [
          { addressConfig = { Address = "192.168.1.10/24"; RouteMetric = 512;}; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 512;}; }
        ];
      };

    };
  };

  boot.kernelModules = [ "kvm-amd" "vfio-pci" ];

  # load vfio drivers for the amd pci devices
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

  users.users.annasavage = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOFQPx3v0jpbhPbeLwjzbrdVXJQjba7vB22RCJ8NUBfiZ9RDtL/buxD95+lUQewnC5GmHfbiUuaRExODeYAjBcX0Yqf5WlrqAAcuLKFm1D1gr2gP9+SFYdtG7iQUAVPptEgGhgfm0PGDDj3bu+2bKAlYW6B8hhN8aOoJ8UD6t6JEv1UZq64v1acvcNv3BQ+S0/vQI0W48AYknSj2j1JrqKDzxSPXpzLiy8iSLEAq0lcFsb6wPnZvyzt87Wp+jRd+NPCYzER+DLYI+U0LmZQg4H03qKC+2ZVFzyeiB8uG9X+4LLBUoSE9eMIb8h0jJ5/3BgWE83P5pJgLxgn4vEw6NtulzhxUyFOmvYGiayEbwHyflAYBGVNcUZlPTef+qVI/JTvLf327JQKNBgm6mkzgiSpU3wAZmyu/XhYWaXlPWYVs/ItkiTujcnP32oYbke66u70nRNky3fRhG6zCcOLGyS+Bil8OWxDTM/oKMEDEMbg7O4uVlQYgydPoh/YqqPFnc= savagea@pyxis" ];
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];

  swapDevices = [ ];

  hardware.enableRedistributableFirmware = true;

}
