{ config, pkgs, ... }:
{
  users.users = {
    annasavage = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./public/ssh/annasavage.pub)
      ];
    };

    root = {
      extraGroups = [ "wheel" ];
    };

    danielbarter = {

      # creates /var/lib/systemd/linger/danielbarter
      linger = true;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "audio"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./public/ssh/id_rsa.pub)
        (builtins.readFile ./public/ssh/phone.pub)
      ];
    };
  };
}
