{
  config,
  lib,
  ...
}:
let
  host = config.networking.hostName;
  encrypted = builtins.fromJSON (builtins.readFile (./secrets + "/${host}.json"));
  keyNames = prefix: builtins.filter
    (name: name == prefix || lib.hasPrefix "${prefix}-" name)
    (builtins.attrNames encrypted);
  passageKeys = keyNames "passage-identity";
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
      }
      // lib.genAttrs (keyNames "ssh-client") (_: {
        owner = "danielbarter";
        mode = "0400";
      })
      // lib.genAttrs (keyNames "nix-signing") (_: {
        restartUnits = [ "nix-daemon.service" ];
      })
      // lib.genAttrs passageKeys (_: {
        owner = "danielbarter";
        mode = "0400";
      })
      // lib.optionalAttrs (host == "blaze") {
        wireguard = {
          group = "systemd-network";
          mode = "0440";
          restartUnits = [ "systemd-networkd.service" ];
        };
        duckdns.restartUnits = [ "ddns-update.service" ];
      };

      templates = lib.optionalAttrs (passageKeys != [ ]) {
        "passage-identities" = {
          owner = "danielbarter";
          mode = "0400";
          content = lib.concatMapStringsSep "\n"
            (name: config.sops.placeholder.${name}) passageKeys;
        };
      };
    };

    environment.sessionVariables = lib.optionalAttrs (passageKeys != [ ]) {
      PASSAGE_DIR = "/home/danielbarter/.password-store";
      PASSAGE_IDENTITIES_FILE = config.sops.templates."passage-identities".path;
    };
  };
}
