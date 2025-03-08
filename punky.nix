{ config, pkgs,... }:
{

  imports = [ ./static-bond-interface.nix ./wireguard-interface.nix ];
  dev-machine = true;

  # we use /dev/shm as a staging area for raw disk images, so the extra space is nice
  boot.devShmSize = "75%";

  # building lots of derivations at once tends to unearth concurrency bugs in build systems
  # also, this machine is also constantly streaming music, which we don't want to interupt
  nix.settings = {
    max-jobs = 2;
    cores = 2;
  };

  systemd.services.llama-cpp = let
    llama-vulkan = pkgs.llama-cpp.override {vulkanSupport = true;};
    model_file = "/ML/deepseek_r1_distill_qwen_14b.gguf";
    layers = "49";
    network_config = "--host 0.0.0.0 --port 80";
  in {
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${llama-vulkan}/bin/llama-server -m ${model_file} -ngl ${layers} ${network_config}";
    };
  };

  # serve DNS stub on local network
  services.resolved.extraConfig = ''
    DNSStubListenerExtra=192.168.1.${config.network-id}
  '';


  # ddns update for LAN
  systemd.services.ddns-update = let
  ddns-update = (pkgs.callPackage ./ddns-update.nix {});
  in {
    wantedBy = [ "timers.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ddns-update}/bin/ddns_update --token_file /etc/nixos/secrets/duckdns_token";
    };
    unitConfig = {
      PartOf = [ "timers.target" ];
    };
  };

  systemd.timers.ddns-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "10min";
    };
  };


  networking = let network-ids = import ./network-ids.nix;
   in {
    hostName = "punky";

    # these get put into /etc/hosts
    hosts = {
      "192.168.1.1" = [ "asusmain.meow" ];
      "192.168.1.2" = [ "asusaux.meow" ];
      "192.168.1.${network-ids.rupert}" = [ "rupert.meow" ];
      "192.168.1.${network-ids.punky}" = [ "punky.meow" ];
      "192.168.1.${network-ids.jasper}" = [ "jasper.meow" ];
    };

    # DNS used by resolved. resolvectl status
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
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
