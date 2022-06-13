{pkgs, ...}:

{
  services.logind.lidSwitch = "suspend";

  # make udev rules for backlight
  programs.light.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.logind = {
    killUserProcesses = false;
    extraConfig = "HandlePowerKey=suspend";
  };


}
