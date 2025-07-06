{ lib, pkgs, ... }:
{
  systemd.sysusers.enable = true;

  # systemd-sysusers is a dependency of systemd-oomd, but this is not encoded
  # in the stock unit files. fixed upstream: https://github.com/systemd/pull/35712
  # add the dependency manually for now
  systemd.services.systemd-oomd.after = [ "systemd-sysusers.service" ];

  users = {

    mutableUsers = false;

    users = {
      danielbarter = {
        isSystemUser = true;
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


      systemd-network = {
        extraGroups = [ "users" "wheel" ];
      };

      nix-ssh = {
        openssh.authorizedKeys.keyFiles = [
            "/etc/nixos/public/ssh/id_rsa.pub"
        ];
      };

    };
  };
}
