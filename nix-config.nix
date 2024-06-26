{
  lib,
  config,
  pkgs,
  ...
}:

{

  nix = {
    settings.experimental-features = "nix-command flakes";

    # wipe the default flake registry
    extraOptions =
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
      '';
  };

}
