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

  systemd.user.services.powertop = {
    description = "pueued daemon";
    bindsTo = [ "default.target" ];
    wants = [ "default.target" ];
    after = [ "default.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = '' ${pkgs.powertop}/bin/powertop --auto-tune'';
    };
  };

  powerManagement.powertop.enable = true;

  # make udev rules for backlight
  programs.light.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
