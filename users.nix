{ lib, pkgs, ... }:
{


  services.userborn.enable = true;

  # oomd needs users to be up before starting
  systemd.services.systemd-oomd.after = [ "userborn.service" ];

  users = {

    mutableUsers = false;

    users = {
      danielbarter = {
        isNormalUser = true;
        # creates /var/lib/systemd/linger/danielbarter
        linger = true;

        # needed so gemini can make sandboxes?
        subUidRanges = [ { startUid = 100000; count = 65536; } ];
        subGidRanges = [ { startGid = 100000; count = 65536; } ];

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
