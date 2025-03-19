{ config, pkgs,... }:
{

  imports = [
    ./static-bond-interface.nix
    ./wireguard-interface.nix
    ./wireless.nix
    ./intel-gpu.nix
  ];

  dev-machine = true;

  # we use /dev/shm as a staging area for raw disk images, so the extra space is nice
  boot.devShmSize = "75%";

  # building lots of derivations at once tends to unearth concurrency bugs in build systems
  nix.settings = {
    max-jobs = 2;
    cores = 3;
  };


  networking = {
    hostName = "punky";
    
    # DNS used by resolved. resolvectl status
    nameservers = [
      "192.168.1.${(import ./network-ids.nix).blaze}"
    ];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/cfbddc74-a767-40f2-993d-729d1a5758b9";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/4CF2-BE53";
      fsType = "vfat";
    };

    "/ML" = {
      device = "/dev/disk/by-uuid/308bd10e-7a18-4610-8c7d-757a098ef2dc";
      fsType = "ext4";
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
