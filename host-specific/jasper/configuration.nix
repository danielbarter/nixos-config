{pkgs, ...}:

{
  services.logind.lidSwitch = "suspend";

  # make udev rules for backlight
  programs.light.enable = true;


  boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs.config.allowUnfree = true;
}
