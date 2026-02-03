{
  pkgs,
  modulesPath,
  ...
}:
{

  imports = [
    "${modulesPath}/profiles/docker-container.nix"
  ];

  boot.isNspawnContainer = true;
  console.enable = true;

  nix.extraOptions =
    let
      emptyFlakeRegistry = pkgs.writeText "flake-registry.json" (
        builtins.toJSON {
          flakes = [ ];
          version = 2;
        }
      );
    in
    ''
      flake-registry = ${emptyFlakeRegistry};
      experimental-features = nix-command flakes
    '';


  system.stateVersion = "25.11";
  users.users.root.initialHashedPassword = "";
}
