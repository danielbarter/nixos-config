{lib,config,...}:
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    # store public keys in a single location
    authorizedKeysInHomedir = false;
  
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  # for containers, don't specify ssh key
  programs.ssh.extraConfig = lib.optionalString (! config.boot.isContainer)
    ''
    Host *
        IdentityFile /etc/nixos/secrets/ssh/id_rsa
    '';
}
