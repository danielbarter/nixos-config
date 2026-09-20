{
  lib,
  pkgs,
  config,
  ...
}:
let
  managed = config.secretsManagement.enable;
in {


  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-public-keys = [ (builtins.readFile ./keys/nix/signing.pub) ];
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
      '' + lib.optionalString managed ''
        secret-key-files = ${config.sops.secrets.nix-signing.path}
      '';
  };

}
