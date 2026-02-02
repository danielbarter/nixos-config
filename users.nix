{ lib, pkgs, config, ... }:
{

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
          "/cold/public/ssh/id_rsa.pub"
          "/cold/public/ssh/phone.pub"
        ];

        initialHashedPassword = lib.strings.fileContents "/cold/secrets/user_password_hash";

        shell = pkgs.bashInteractive;
        home = "/home/danielbarter";
      };

      root = { 
        initialHashedPassword = lib.strings.fileContents "/cold/secrets/root_password_hash";
        extraGroups = [ "users" "wheel" ];
      };

      # serve nix store over ssh
      nix-ssh = {
        openssh.authorizedKeys.keyFiles = [
            "/cold/public/ssh/id_rsa.pub"
        ];
      };

    };
  };
}
