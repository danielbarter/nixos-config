{pkgs, ...}:

{
  services.logind.lidSwitch = "suspend";

  # service for improving battery life
  services.tlp = {
    enable = true;
    settings = {
      PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };

  powerManagement.powertop.enable = true;

  # make udev rules for backlight
  programs.light.enable = true;


  boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs.config.allowUnfree = true;
}
