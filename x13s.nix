{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let dtb = "${config.boot.kernelPackages.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
in {

  boot = {

    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      grub.enable = false;
    };

    initrd = {
      # use systemd in stage 1. Easier to diagnose issues when they arise
      systemd = {
        enable = true;
        emergencyAccess = true;
      };

      availableKernelModules = [
        "i2c-core"
        "i2c-hid"
        "i2c-hid-of"
        "i2c-qcom-geni"
        "pcie-qcom"
        "phy-qcom-qmp-combo"
        "phy-qcom-qmp-pcie"
        "phy-qcom-qmp-usb"
        "phy-qcom-snps-femto-v2"
        "phy-qcom-usb-hs"
        "ext4"
        "usb_storage"
        "usbhid"
      ];
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
      "dtb=x13s.dtb"
    ];

  };



  imports = [ "${modulesPath}/image/repart.nix" ];

  fileSystems."/efi".device = "/dev/disk/by-label/EFI";
  fileSystems."/nix/store".device = "/dev/disk/by-label/nix-store";

  # root should be a filesystem contained in ram so that machine operation is
  # not cripplingly slow
  fileSystems."/" = {
    label = "root";
    fsType = "tmpfs";
    options = [ "size=4G" ];
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

            "/x13s.dtb".source = dtb;

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
      };
    };
}
