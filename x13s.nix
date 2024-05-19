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
      "phy-qcom-qmp-combo"
      "phy-qcom-qmp-pcie"
      "phy-qcom-qmp-usb"
      "phy-qcom-snps-femto-v2"
      "phy-qcom-usb-hs"
    ];

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
      "dtb=x13s.dtb"
      "efi=noruntime"
    ];
  };
}

