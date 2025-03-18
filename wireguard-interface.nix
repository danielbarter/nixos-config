{config,pkgs,...}:
{

  environment.systemPackages = [ pkgs.wireguard-tools ];

  systemd.network = {
    netdevs = {
      "30-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          PrivateKeyFile = "/etc/nixos/secrets/wireguard/${config.networking.hostName}";
          ListenPort = 51820;
        };
        wireguardPeers = import ./wireguard-peers.nix; 
      };
    };

    networks = {
      "30-wg0" = {
        matchConfig.Name = "wg0";

        networkConfig = {
          DHCP = "no";
        };

        address = ["192.168.2.${config.network-id}/24"];
      };
    };
  };
}
