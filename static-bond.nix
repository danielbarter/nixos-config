{
  pkgs,
  config,
  lib,
  ...
}:
{
  # most standard desktops come with a wireless interface and an ethernet interface
  # we want to put them behind a bond interface, and assign a static ip, since they
  # live in a house where the router is on 192.168.1.1
  options.network-id = lib.mkOption {
    type = lib.types.int;
    description = "id used for static IP: 192.168.1.x";
  };

  config = {
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
            MIIMonitorSec = "1s";
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
            DHCP = "no";
            MulticastDNS = "yes";
          };

          addresses = [
            {
              Address = "192.168.1.${builtins.toString config.network-id}/24";
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
  };
}
