{
  modulesPath,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/docker-image.nix"
  ];

  # openssh broken inside systemd-nspawn for some reason
  services.openssh.enable = lib.mkForce false;
}
