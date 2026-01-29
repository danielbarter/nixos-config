{
  pkgs,
  modulesPath,
  lib,
  config,
  ...
}:
let
    replicant-nixos-config = builtins.path {
      path = /tmp/nixos.zip.gpg;
      name = "nixos.zip.gpg";
    };
in {

  imports = [
    "${modulesPath}/image/repart.nix"
  ];

  # forces sysinit to block until setup-replicant has finished
  systemd.targets.sysinit.requires = [ "setup-replicant.service" ];
  systemd.targets.sysinit.after = [ "setup-replicant.service" ];

  systemd.services.setup-replicant = {
    wantedBy = [ "sysinit.target" ];

    environment = {
      REPLICANT_NIXOS_CONFIG = replicant-nixos-config;
    };

    path = [ config.programs.gnupg.package pkgs.zip pkgs.unzip ];

    unitConfig = {
      DefaultDependencies = "no";
    };

    serviceConfig = {
      Type = "oneshot";
    };

    script = ''
      cp $REPLICANT_NIXOS_CONFIG /nixos.zip.gpg
      cd /

      PASSWORD=$(systemd-ask-password --timeout=0 --no-tty)
      echo $PASSWORD | gpg --pinentry-mode loopback  --passphrase-fd 0 /nixos.zip.gpg
      unzip /nixos.zip

      cd /etc/nixos

      # set permissions for /etc/nixos
      source /etc/nixos/utils/set_permissions.sh

      # setup home
      source /etc/nixos/utils/home_setup.sh
    '';
  };

  system.stateVersion = "24.05";

  networking.hostName = "replicant";

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

        "nix-store-lower" = {
          storePaths = [
            config.system.build.toplevel
            replicant-nixos-config
          ];
          nixStorePrefix = "/";
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
