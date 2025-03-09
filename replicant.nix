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

  # boot partition
  fileSystems."/efi".device = "/dev/disk/by-label/EFI";

  # root should be a filesystem contained in ram so that machine operation is
  # not cripplingly slow
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=4G" ];
  };

  # we put the nix store on an overlay filesystem with the lower part in the
  # device image, and the upper part a temp filesystem. this prevents operations
  # which write to the store from being crippilingly slow
  fileSystems."/nix-store-lower" = {
    device = "/dev/disk/by-label/nix-store-lower";
    neededForBoot = true;
  };

  fileSystems."/nix-store-upper" = {
    fsType = "tmpfs";
    options = [ "size=4G" ];
    neededForBoot = true;
  };


  fileSystems."/nix/store" = {
    overlay = {
      lowerdir = [ "/nix-store-lower" ];
      upperdir = "/nix-store-upper/diff";
      workdir = "/nix-store-upper/work";
    };
    # make sure that we don't try and mount nix store before its parts are mounted
    depends = [ "/nix-store-lower" "/nix-store-upper" ];
  };

  imports = [ "${modulesPath}/image/repart.nix" ./wireguard-interface.nix  ];

  boot.kernelParams = let
    serial_tty = {
      x86_64-linux = "console=ttyS0";
      aarch64-linux = "console=ttyAMA0";
      riscv64-linux = "console=ttyS0";
    };
    in [ "console=tty0" serial_tty.${config.nixpkgs.hostPlatform.system} ];

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
        "nix-store-lower" = {
          storePaths = [
            config.system.build.toplevel
            setup-replicant
            replicant-nixos-config
          ];
          stripNixStorePrefix = true;
          repartConfig = {
            Type = "linux-generic";
            Format = "ext4";
            Label = "nix-store-lower";
            Minimize = "guess";
          };
        };
      };
    };
}
