{config, pkgs, ...}:
let
  windows = pkgs.writeTextFile {
    name = "windows";
    destination = "/bin/windows";
    executable = true;
    text = ''
         #!${pkgs.bash}/bin/bash
         export LIBVIRT_DEFAULT_URI=qemu:///system
         if [ "$1" = "start" ]
         then
           ${pkgs.libvirt}/bin/virsh start win10
           exit
         fi

         if [ "$1" = "status" ]
         then
           ${pkgs.libvirt}/bin/virsh list --all
           exit
         fi

         echo "usage: windows start|status"
    '';
  };
  in
{

  nix = {
    settings = {
      substituters = [
        # "http://punky:5000"
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = [
        (builtins.readFile ./secrets/binary-cache/cache-pub-key.pem)
      ];
    };
  };



  systemd.services.windows-control-server = {
    after = [ "network.target" ];

    # require service at boot time
    wantedBy = [ "multi-user.target" ];
    path = [ windows ];

    serviceConfig = {
      WorkingDirectory="/etc/nixos/utils/windows_control_server";
      ExecStart = "${pkgs.python310Packages.gunicorn}/bin/gunicorn -w 1 -b 0.0.0.0:80 windows_control_server:run";
    };
  };

  environment.systemPackages = [ windows ];

  networking.hostName = "rupert";

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
