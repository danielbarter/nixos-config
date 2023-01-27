{config, pkgs, ...}:
{

  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nixos/secrets/binary-cache/cache-priv-key.pem";
  };

    # serve DNS stub on local network
  services.resolved.extraConfig = ''
       DNSStubListenerExtra=192.168.1.12
  '';


  systemd.network = {
    networks = {
      "40-wlan0" = {
        matchConfig = {
          Name = "wlan0";
        };

        networkConfig = {
          DHCP = "no";
        };

        addresses = [
          { addressConfig = { Address = "192.168.1.11/24"; RouteMetric = 1024;}; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 1024;}; }
        ];
      };

      "40-enp88s0" = {
        matchConfig = {
          Name = "enp37s0";
        };

        networkConfig = {
          DHCP = "no";
        };

        addresses = [
          { addressConfig = { Address = "192.168.1.10/24"; RouteMetric = 512;}; }
        ];

        routes = [
          { routeConfig = { Gateway = "192.168.1.1"; Metric = 512;}; }
        ];
      };

    };
  };



  # these get put into /etc/hosts
  networking = {

    hostName = "punky";

    hosts = {
      "192.168.1.1" = [ "asusmain" ];
      "192.168.1.2" = [ "asusaux" ];
      "192.168.1.10" = [ "rupert" ];
      "192.168.1.11" = [ "rupertwireless" ];
      "192.168.1.12" = [ "punky" ];
      "192.168.1.13" = [ "punkywireless" ];
    };

    # DNS used by resolved. resolvectl status
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

}
