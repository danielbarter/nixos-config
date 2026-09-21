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
  passageKeys = keyNames "passage-identity";
  hasPassGpg = builtins.hasAttr "pass-gpg" encrypted;
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
      // lib.optionalAttrs hasPassGpg {
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

    # Keep GPG available until this host has completed the Passage migration.
    programs.gnupg.agent = lib.mkIf hasPassGpg {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

    systemd.services.pass-gpg-import = lib.mkIf hasPassGpg {
      description = "Import the legacy password-store GPG key";
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
