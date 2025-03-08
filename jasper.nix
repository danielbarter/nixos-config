{
  config,
  pkgs,
  lib,
  ...
}:

{

  imports = [ ./static-bond-interface.nix ];
  dev-machine = true;
  network-id = (import ./network-ids.nix).${config.networking.hostName};


  networking = {
    hostName = "jasper";
    
    nameservers = [
      "192.168.1.12"
    ];
  };

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  services.logind = {
    extraConfig = "HandlePowerKey=suspend";
  };

  programs.adb.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3e74cb7c-1f46-4a90-af40-04ac22c54d2e";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A65D-C287";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
