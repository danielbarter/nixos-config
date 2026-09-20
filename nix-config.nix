{
  lib,
  pkgs,
  config,
  ...
}:
let
  managed = config.secretsManagement.enable;
  publicKeys = builtins.readDir ./keys/nix;
  signingKeys = builtins.filter
    (name: name == "nix-signing" || lib.hasPrefix "nix-signing-" name)
    (builtins.attrNames config.sops.secrets);
in {


  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-public-keys = map (name: lib.strings.fileContents (./keys/nix + "/${name}")) (
        builtins.filter (name: publicKeys.${name} == "regular" && lib.hasSuffix ".pub" name)
          (builtins.attrNames publicKeys)
      );
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
        secret-key-files = ${lib.concatMapStringsSep " " (name: config.sops.secrets.${name}.path) signingKeys}
      '';
  };

}
