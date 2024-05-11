{pkgs, ...}: {
  system.stateVersion = "23.05";

  # set password to be empty for root
  users.users.root.initialPassword = "";


  # add encrypted, zipped nixos config to iso
  isoImage.contents = [
    {
      source = /tmp/nixos.zip.gpg;
      target = "nixos.zip.gpg";
    }

    {
      source = ./utils/setup_replicant_iso.sh;
      target = "setup_replicant_iso.sh";
    }
  ];


  hardware.enableAllFirmware = true;

  networking = {
    hostName = "replicant";
  };


  # catchall network config. Configure whatever interface is present
  systemd.network.networks = {
    "40-generic" = {
      matchConfig = {
        Name = "*";
      };
      networkConfig = {
        DHCP = "yes";
      };
    };
  };
}
