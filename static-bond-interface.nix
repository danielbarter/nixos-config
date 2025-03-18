{
  config,
  ...
}:
{
# most standard desktops come with a wireless interface and an ethernet interface
# we want to put them behind a bond interface, and assign a static ip
  systemd.network = {
    netdevs = {
      "30-bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };

        bondConfig = {
          Mode = "active-backup";
          PrimaryReselectPolicy = "always";
          MIIMonitorSec = "10s";
        };
      };
    };

    networks = {
    
      "30-eth" = {
        matchConfig = {
          Name = "en*";
        };

        networkConfig = {
          Bond = "bond0";
          PrimarySlave = true;
        };
      };

      "30-wlan" = {
        matchConfig = {
          Name = "wl*";
        };

        networkConfig = {
          Bond = "bond0";
        };
      };

      "30-bond0" = {
        matchConfig = {
          Name = "bond0";
        };

        networkConfig = {
          Gateway = "192.168.1.${(import ./network-ids.nix).blaze}";
          Address = "192.168.1.${config.network-id}/24";
        };
      };
    };
  };
}
