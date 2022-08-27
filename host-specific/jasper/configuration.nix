{pkgs, ...}:

{
  services.logind.lidSwitch = "suspend";

  # utility for controlling power settings
  powerManagement.powertop.enable = true;

  # make udev rules for backlight
  programs.light.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.logind = {
    killUserProcesses = false;
    extraConfig = "HandlePowerKey=suspend";
  };


}
