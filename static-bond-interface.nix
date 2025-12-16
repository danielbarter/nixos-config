{
  pkgs,
  config,
  ...
}:
{

  # since we don't have a DHCP client running, we need
  # to manually set DNS
  networking = { 
    nameservers = [
      "192.168.1.${(import ./network-ids.nix).blaze}"
    ];
  };

  # on everything except the router, we don't want to run
  # DNS stub listner
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';


  # this config is for headless systems without network manager. So we use iwd for
  # wireless interface configuration
  networking.wireless.iwd.enable = true;
  environment.systemPackages = [ pkgs.iw ];

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
