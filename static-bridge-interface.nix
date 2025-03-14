{
  config,
  ...
}:
{
# standard desktop with a wireless and an ethernet interface
# we want to bridge them so that we can quickly add devices
# with no wifi to the network
  systemd.network = {
    netdevs = {
      "30-bridge0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "bridge0";
        };
      };
    };

    networks = {
    
      "30-eth" = {
        matchConfig = {
          Name = "en*";
        };

        networkConfig = {
          Bridge = "bridge0";
        };
      };

      "30-wlan" = {
        matchConfig = {
          Name = "wl*";
        };

        networkConfig = {
          Bridge = "bridge0";
        };
      };

      "30-bridge0" = {
        matchConfig = {
          Name = "bridge0";
        };

        networkConfig = {
          DHCP = "no";
          MulticastDNS = "yes";
        };

        addresses = [
          {
            Address = "192.168.1.${config.network-id}/24";
          }
        ];

        routes = [
          {
            Gateway = "192.168.1.1";
          }
        ];
      };
    };      
  };
}
