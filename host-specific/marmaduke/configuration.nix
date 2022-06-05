{pkgs, ...}:

{
  services.logind.lidSwitch = "suspend";

  # make udev rules for backlight
  programs.light.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
