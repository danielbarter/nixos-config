{pkgs, ...}:

{

  networking = {
    useNetworkd = true;
    interfaces."wlan0".useDHCP = true;
  };

  services.logind.lidSwitch = "suspend";

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
