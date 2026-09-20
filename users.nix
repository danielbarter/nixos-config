{ lib, pkgs, config, ... }:
let
  managed = config.secretsManagement.enable;
  sshKeys = builtins.readDir ./keys/ssh;
  hostKeyFiles = map (name: ./keys/ssh + "/${name}") (
    builtins.filter (name:
      sshKeys.${name} == "regular" && lib.hasSuffix ".pub" name && name != "phone.pub"
    ) (builtins.attrNames sshKeys)
  );
in {

  users = {

    mutableUsers = false;

    users = {
      danielbarter = {
        isNormalUser = true;
        # creates /var/lib/systemd/linger/danielbarter
        linger = true;

        group = "users";
        extraGroups = [
          "video"
          "audio"
          "wheel"
        ];
        openssh.authorizedKeys.keyFiles = hostKeyFiles ++ [ ./keys/ssh/phone.pub ];

        shell = pkgs.bashInteractive;
        home = "/home/danielbarter";
      } // lib.optionalAttrs managed {
        hashedPasswordFile = config.sops.secrets.user-password.path;
      } // lib.optionalAttrs (!managed) {
        hashedPassword = lib.mkDefault "!";
      };

      root = {
        extraGroups = [ "users" "wheel" ];
      } // lib.optionalAttrs managed {
        hashedPasswordFile = config.sops.secrets.root-password.path;
      } // lib.optionalAttrs (!managed) {
        hashedPassword = lib.mkDefault "!";
      };

      # serve nix store over ssh
      nix-ssh = {
        openssh.authorizedKeys.keyFiles = hostKeyFiles;
      };

    };
  };
}
