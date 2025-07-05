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

    programs.ssh.extraConfig = ''
    Host *
        IdentityFile /etc/nixos/secrets/ssh/id_rsa
    '';
}
