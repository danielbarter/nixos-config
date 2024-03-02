{pkgs, lib, ...}: {
  system.stateVersion = "23.05";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  users.users.test = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  services.getty.autologinUser = "test";
}
