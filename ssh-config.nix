{ config, lib, ... }:
let
  managed = config.secretsManagement.enable;
in {
  # Enable the OpenSSH daemon.
  services.openssh = {
    # store public keys in a single location
    authorizedKeysInHomedir = false;
  
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  programs.ssh.extraConfig = lib.optionalString managed ''
    Host *
        IdentityFile ${config.sops.secrets.ssh-client.path}
  '';
}
