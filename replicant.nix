{pkgs, modulesPath, lib, config, ...}: {

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


  boot.loader.grub.enable = false;

  fileSystems."/".device = "/dev/disk/by-label/nixos";

  imports = [ "${modulesPath}/image/repart.nix" ];

  image.repart = let efiArch = pkgs.stdenv.hostPlatform.efiArch; in {
    name = "image";
    partitions = {
      "esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

          "/loader/entries/nixos.conf".source = pkgs.writeText "nixos.conf" ''
          title NixOS
          linux /EFI/nixos/kernel.efi
          initrd /EFI/nixos/initrd.efi
          options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} console=tty0 console=ttyS0
          '';

          "/EFI/nixos/kernel.efi".source =
            "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";

          "/EFI/nixos/initrd.efi".source =
            "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = "96M";
        };
      };

      "root" = {
        storePaths = [ config.system.build.toplevel ];
        contents = {
          # add encrypted zipped nixos config to iso
          "/setup_replicant.sh".source = ./utils/setup_replicant.sh;
          "/nixos.zip.gpg".source = /tmp/nixos.zip.gpg;
        };
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "nixos";
          Minimize = "guess";
        };
      };
    };
  };


}


