{
  config,
  lib,
  pkgs,
  ...
}:
let
  host = config.networking.hostName;
  encrypted = builtins.fromJSON (builtins.readFile (./secrets + "/${host}.json"));
  keyNames = prefix: builtins.filter
    (name: name == prefix || lib.hasPrefix "${prefix}-" name)
    (builtins.attrNames encrypted);
in
{
  config = {
    fileSystems."/cold" = {
      device = "/dev/disk/by-label/cold";
      fsType = "ext4";
      options = [ "ro" ];
      neededForBoot = true;
    };

    sops = lib.mkIf config.secretsManagement.enable {
      defaultSopsFile = ./secrets + "/${host}.json";
      defaultSopsFormat = "json";
      age = {
        keyFile = "/cold/age/key.agekey";
        generateKey = false;
        sshKeyPaths = [ ];
      };
      gnupg.sshKeyPaths = [ ];
      secrets = {
        user-password.neededForUsers = true;
        root-password.neededForUsers = true;
        pass-gpg = {
          owner = "danielbarter";
          mode = "0400";
          restartUnits = [ "pass-gpg-import.service" ];
        };
      }
      // lib.genAttrs (keyNames "ssh-client") (_: {
        owner = "danielbarter";
        mode = "0400";
      })
      // lib.genAttrs (keyNames "nix-signing") (_: {
        restartUnits = [ "nix-daemon.service" ];
      })
      // lib.optionalAttrs (host == "blaze") {
        wireguard = {
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd.service" ];
        };
        duckdns.restartUnits = [ "ddns-update.service" ];
      };
    };

    # pass keeps using ~/.gnupg. This imports new subkeys after a pull and
    # rebuild, so there is no wrapper and no second GPG home.
    systemd.services.pass-gpg-import = lib.mkIf config.secretsManagement.enable {
      description = "Import the pass GPG key";
      wantedBy = [ "multi-user.target" ];
      after = [ "sops-install-secrets.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "danielbarter";
        Environment = [
          "HOME=/home/danielbarter"
          "GNUPGHOME=/home/danielbarter/.gnupg"
        ];
        ExecStart = "${pkgs.gnupg}/bin/gpg --batch --import ${config.sops.secrets.pass-gpg.path}";
      };
    };
  };
}
