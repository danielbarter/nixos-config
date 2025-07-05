{

  imports = [ ./sound.nix ];

  programs.firefox.enable = true;
  programs.steam.enable = true;

  # controls the max number of memory mapped areas a process can have
  # modern games have been hitting the default limit which is low
  # 512 * 1024 = 524288
  boot.kernel.sysctl = {
    "vm.max_map_count" = 524288;
  };


  networking = {
    hostName = "rupert";
  };

  boot.kernelModules = [ "hid-nintendo" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f3dcb6ca-b39f-4c0a-86a7-72f9f331a1e0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6146-A760";
    fsType = "vfat";
  };

  fileSystems."/home/danielbarter/windows" = {
    device = "/dev/disk/by-label/windows";
    fsType = "ext4";
  };

  services.logind = {
    extraConfig = ''
      HandlePowerKey=ignore
      HandlePowerKeyLongPress=poweroff
    '';
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];

  swapDevices = [ ];



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
