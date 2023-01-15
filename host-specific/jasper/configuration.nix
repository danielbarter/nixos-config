{config, pkgs, ...}:

{

  imports = [ ./gui.nix ];

  nix = {
    settings = {
      substituters = [
        # "http://rupert:5000"
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = [
        (builtins.readFile ./secrets/binary-cache/cache-pub-key.pem)
      ];
    };
  };

  # these get put into /etc/hosts
  networking = {
    hostName = "jasper";
    hosts = {
    "192.168.1.1" = [ "asusmain" ];
    "192.168.1.2" = [ "asusaux" ];
    "192.168.1.10" = [ "rupert" ];
    "192.168.1.11" = [ "rupertwlan" ];
    };
  };

  systemd.network = {
    networks = {
      "40-wlan0" = {
        matchConfig = {
          Name = "wlan0";
        };

        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };

  services.logind.lidSwitch = "suspend";

  # enable android debug bridge
  programs.adb.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware = {
    # steam client needs 32 bit video/audio drivers to start
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];

    # lets steam interact with hardware
    steam-hardware.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # kernel module for switch pro controller
  boot.kernelModules = [ "hid-nintendo" "kvm-intel" ];

  services.logind = {
    extraConfig = "HandlePowerKey=suspend";
  };

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
  # high-resolution display
  hardware.video.hidpi.enable =  true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.11";  # Did you read the comment?
}
