{lib, config, pkgs, flake-outputs-args,  ... }:

{

  nix.settings.experimental-features = "nix-command flakes";
  # use our flake input for resolving <nixpkgs>
  nix = {

    nixPath = [ "nixpkgs=${flake-outputs-args.nixpkgs.outPath}" ];

    # wipe the default flake reg, and set it to be our system nixpkgs
    extraOptions = let
      emptyFlakeRegistry = pkgs.writeText "flake-registry.json"
        (builtins.toJSON { flakes = []; version = 2; });
      in
      ''
        flake-registry = ${emptyFlakeRegistry};
    '';

  };

  nix.registry.nixpkgs.flake = flake-outputs-args.nixpkgs;


}
