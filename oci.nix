{
  modulesPath,
  ...
}:
{

  imports = [
    "${modulesPath}/nixos/modules/virtualisation/docker-image.nix"
  ];
}
