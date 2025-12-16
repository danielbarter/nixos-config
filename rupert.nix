{

  programs.steam.enable = true;

  networking.hostName = "rupert";

  services.avahi.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8c60622d-bf09-46be-9557-30f4c25bd560";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
  };

  fileSystems."/home/danielbarter" = {
    device = "/dev/disk/by-uuid/a1573720-4b5e-4211-90fe-9eb9e9e5be3c";
    fsType = "btrfs";
  };


  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };


  # controls the max number of memory mapped areas a process can have
  # modern games have been hitting the default limit which is low
  # 512 * 1024 = 524288
  boot.kernel.sysctl = {
    "vm.max_map_count" = 524288;
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
