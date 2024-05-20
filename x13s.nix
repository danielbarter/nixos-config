{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{

  boot = {

    loader.efi.canTouchEfiVariables = lib.mkForce false;

    initrd.availableKernelModules = [
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
    ];

    kernelPackages = pkgs.linuxPackagesFor (pkgs.buildLinux {
      version = "6.9.0-rc7";
      defconfig = "johan_defconfig";
      src = pkgs.fetchurl {
        url = "https://github.com/jhovold/linux/archive/refs/heads/wip/sc8280xp-6.9-rc7.tar.gz";
        hash = "sha256-2cPRW6KXRVzJFIlIt+FgjmjSETuYSDFzRPPuxpvp/lM=";
      };
    });

    kernelParams = [
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
      "dtb=x13s.dtb"
      "efi=noruntime"
    ];
  };
}

