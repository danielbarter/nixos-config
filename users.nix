{ lib, ... }:
{
  users = {
    mutableUsers = false;
    users = {

      annasavage = {
        isNormalUser = true;
        openssh.authorizedKeys.keyFiles = [
          "/etc/nixos/public/ssh/annasavage.pub"
        ];
      };

      root.extraGroups = [ "wheel" ];
      systemd-network.extraGroups = [ "wheel" ];

      nix-ssh.openssh.authorizedKeys.keyFiles = [
          "/etc/nixos/public/ssh/id_rsa.pub"
      ];

      danielbarter = {

        # creates /var/lib/systemd/linger/danielbarter
        linger = true;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "video"
          "audio"
        ];
        openssh.authorizedKeys.keyFiles = [
          "/etc/nixos/public/ssh/id_rsa.pub"
          "/etc/nixos/public/ssh/phone.pub"
        ];

        hashedPassword = lib.strings.fileContents "/etc/nixos/secrets/user_password_hash";
      };

      root = { 
        hashedPassword = lib.strings.fileContents "/etc/nixos/secrets/root_password_hash";
      };
    };
  };
}
