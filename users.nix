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
          "/etc/nixos/public/ssh/id_rsa.pub"
          "/etc/nixos/public/ssh/phone.pub"
        ];

        initialHashedPassword = lib.strings.fileContents "/etc/nixos/secrets/user_password_hash";

        shell = pkgs.bashInteractive;
        home = "/home/danielbarter";
      };

      root = { 
        initialHashedPassword = lib.strings.fileContents "/etc/nixos/secrets/root_password_hash";
        extraGroups = [ "users" "wheel" ];
      };

      # serve nix store over ssh
      nix-ssh = {
        openssh.authorizedKeys.keyFiles = [
            "/etc/nixos/public/ssh/id_rsa.pub"
        ];
      };

    };
  };
}
