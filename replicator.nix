{...}: {
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
      source = /etc/nixos/utils/setup_replicator_iso.sh;
      target = "setup_replicator_iso.h";
    }
  ];

  boot.kernelModules = [
    # closed source intel wifi drivers
    "iwlwifi"
  ];

  networking = {
    hostName = "replicator";
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
