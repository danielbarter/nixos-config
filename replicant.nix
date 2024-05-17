{
  pkgs,
  modulesPath,
  lib,
  config,
  ...
}:
{

  system.stateVersion = "23.05";

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
  fileSystems."/setup".device = "/dev/disk/by-label/setup";

  # root should be a filesystem contained in ram so that machine operation is
  # not cripplingly slow
  fileSystems."/" = {
    label = "root";
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
            "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

            "/EFI/nixos/kernel.efi".source = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";

            "/EFI/nixos/initrd.efi".source = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";

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

        "nix-store" = {
          storePaths = [ config.system.build.toplevel ];
          stripNixStorePrefix = true;
          repartConfig = {
            Type = "linux-generic";
            Format = "ext4";
            Label = "nix-store";
            Minimize = "guess";
          };
        };

        "setup" = {
          contents = {
            # add encrypted zipped nixos config to iso
            "/setup_replicant.sh".source = ./utils/setup_replicant.sh;
            "/nixos.zip.gpg".source = /tmp/nixos.zip.gpg;
          };

          repartConfig = {
            Type = "linux-generic";
            Format = "ext4";
            Label = "setup";
            Minimize = "guess";
          };
        };
      };
    };
}
