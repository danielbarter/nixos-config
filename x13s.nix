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


    # see https://github.com/jhovold/linux
    # and https://kernel-recipes.org/en/2023/schedule/the-arm-laptop-project
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
      "nvme"
      "leds_qcom_lpg"
      "pwm_bl"
      "qrtr"
      "pmic_glink_altmode"
      "gpio_sbu_mux"
      "gpucc_sc8280xp"
      "dispcc_sc8280xp"
      "phy_qcom_edp"
      "panel_edp"
      "msm"
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

