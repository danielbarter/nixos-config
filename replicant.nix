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
      source = /etc/nixos/utils/setup_replicant_iso.sh;
      target = "setup_replicant_iso.sh";
    }
  ];

  # allow closed source firmware
  hardware.enableRedistributableFirmware = true;

  # we are probably going to be running on some intel chip,
  # so make sure that we have VA-API drivers so firefox is happy
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
      intel-media-driver
    ];
  };



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
