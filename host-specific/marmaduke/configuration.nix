{pkgs, ...}:

{
  services.logind.lidSwitch = "suspend";

  # make udev rules for backlight
  programs.light.enable = true;


}
