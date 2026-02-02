{
  pkgs,
  ...
}:

{


  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-public-keys = [ (builtins.readFile "/cold/public/nix/public-key") ];
      trusted-users = [ "danielbarter" ];
    };


    sshServe = {
      enable = true;
  };

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
        secret-key-files = /cold/secrets/nix/private-key
      '';
  };

}
