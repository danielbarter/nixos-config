{ config, pkgs, ... }:
{
  # allow processes to persist after logout
  services.logind.killUserProcesses = false;

  # equivalent to loginctl enable-linger danielbarter
  # which doesn't like nixos filesystem flags
  system.activationScripts.enableLingering = ''
      # remove all existing lingering users
      rm -r /var/lib/systemd/linger
      mkdir /var/lib/systemd/linger
      # enable for danielbarter
      touch /var/lib/systemd/linger/danielbarter
    '';

}