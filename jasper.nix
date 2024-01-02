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
        IgnoreCarrierLoss = "3s"; # make sure systemd-networkd doesn't reconfigure interface while roaming between APs
        MulticastDNS = "yes";
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

  boot = {
    kernelModules = [ "kvm-intel" ];

    kernelParams = [
      # Fixes a regression in s2idle
      # making it more power efficient than deep sleep
      "mem_sleep_default=s2idle"
      "acpi_osi=\"!Windows 2020\""
      # For Power consumption
      # https://community.frame.work/t/linux-battery-life-tuning/6665/156
      "nvme.noacpi=1"
    ];
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

  # intel_gpu_top
  environment.systemPackages = [ pkgs.intel-gpu-tools ];

  # enabling opencl
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-vaapi-driver
      libvdpau-va-gl
      intel-media-driver
    ];
  };


  powerManagement.cpuFreqGovernor =  "powersave";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.11";  # Did you read the comment?
}
