{}:
{
  system.stateVersion = "24.05";

  networking = {
    hostName = "marmaduke";
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
