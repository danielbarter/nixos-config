{pkgs, lib, ...}: {
  system.stateVersion = "23.05";
  nixpkgs.buildPlatform.system = "x86_64-linux";
  nixpkgs.hostPlatform.system = "aarch64-linux";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = lib.mkForce 0;
  };

  users.users.test = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  services.getty.autologinUser = "test";
}
