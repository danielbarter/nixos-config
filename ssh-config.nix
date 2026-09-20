{ config, lib, ... }:
let
  managed = config.secretsManagement.enable;
  keyNames = builtins.filter
    (name: name == "ssh-client" || lib.hasPrefix "ssh-client-" name)
    (builtins.attrNames config.sops.secrets);
  orderedKeys = lib.optional (builtins.elem "ssh-client-next" keyNames) "ssh-client-next"
    ++ builtins.filter (name: name != "ssh-client-next") keyNames;
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
    ${lib.concatMapStringsSep "\n" (name: "    IdentityFile ${config.sops.secrets.${name}.path}") orderedKeys}
  '';
}
