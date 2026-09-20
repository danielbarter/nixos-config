{ lib, pkgs, config, ... }:
let
  managed = config.secretsManagement.enable;
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
        openssh.authorizedKeys.keyFiles = [
          ./keys/ssh/legacy.pub
          ./keys/ssh/phone.pub
        ];

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
        openssh.authorizedKeys.keyFiles = [
          ./keys/ssh/legacy.pub
        ];
      };

    };
  };
}
