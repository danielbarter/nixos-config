{
  pkgs,
  modulesPath,
  lib,
  config,
  ...
}:
let setup-replicant = builtins.path {
      path = ./utils/setup_replicant.sh;
      name = "setup_replicant.sh";
    };
    replicant-nixos-config = builtins.path {
      path = /tmp/nixos.zip.gpg;
      name = "nixos.zip.gpg";
    };
in {

  environment.variables = {
    SETUP_REPLICANT = setup-replicant;
    REPLICANT_NIXOS_CONFIG = replicant-nixos-config;
  };

  system.stateVersion = "24.05";

  # set password to be empty for root
  users.users.root.initialPassword = "";

  networking = {
    hostName = "replicant";
  };

  # catchall network config. Configure whatever interface is present
  systemd.network.networks = {
    "40-generic" = {
      matchConfig = {
        Name = "*";
      };
      networkConfig = {
        DHCP = "yes";
      };
    };
  };

  # need ext4 kernel module to mount nix store in stage 1
  boot.initrd.availableKernelModules = [
    "ext4"
    "usb_storage"
    "usbhid"
  ];

  fileSystems."/efi".device = "/dev/disk/by-label/EFI";
  fileSystems."/nix/store".device = "/dev/disk/by-label/nix-store";

  # root should be a filesystem contained in ram so that machine operation is
  # not cripplingly slow
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=4G" ];
  };

  imports = [ "${modulesPath}/image/repart.nix" ];

  image.repart =
    let
      efiArch = pkgs.stdenv.hostPlatform.efiArch;
    in
    {
      name = "image";
      partitions = {
        "efi" = {
          contents = {
            "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
              "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

            "/EFI/nixos/kernel.efi".source =
              "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";

            "/EFI/nixos/initrd.efi".source =
              "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";

            "/loader/loader.conf".source = pkgs.writeText "loader.conf" ''
              timeout menu-force
            '';

            "/loader/entries/nixos_console.conf".source = pkgs.writeText "nixos_console.conf" ''
              title NixOS (console)
              linux /EFI/nixos/kernel.efi
              initrd /EFI/nixos/initrd.efi
              options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} console=ttyS0
            '';

            "/loader/entries/nixos.conf".source = pkgs.writeText "nixos.conf" ''
              title NixOS
              linux /EFI/nixos/kernel.efi
              initrd /EFI/nixos/initrd.efi
              options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
            '';
          };
          repartConfig = {
            Type = "esp";
            Format = "vfat";
            SizeMinBytes = "96M";
            Label = "EFI";
          };
        };

        # the generated images are static, so we want to
        # resize the store partition after copying onto a
        # drive.
        # $ nix-shell -p cloud-utils
        # $ doas growpart /dev/sda 2
        # $ doas resize2fs /dev/sda2
        "nix-store" = {
          storePaths = [
            config.system.build.toplevel
            setup-replicant
            replicant-nixos-config
          ];
          stripNixStorePrefix = true;
          repartConfig = {
            Type = "linux-generic";
            Format = "ext4";
            Label = "nix-store";
            Minimize = "guess";
          };
        };
      };
    };
}
