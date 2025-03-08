{
  lib,
  config,
  pkgs,
  ...
}:

{


  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-substituters = [ "ssh://nix-ssh@punky.meow" ];
      trusted-public-keys = [ (builtins.readFile "/etc/nixos/public/nix/public-key") ];
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
        secret-key-files = /etc/nixos/secrets/nix/private-key
      '';
  };

}
