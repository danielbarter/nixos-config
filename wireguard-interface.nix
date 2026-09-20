{
  config,
  ...
}:
{
  systemd.network = {
    netdevs = {
      "30-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets.wireguard.path;
          ListenPort = 51820;
        };
        wireguardPeers = import ./wireguard-peers.nix; 
      };
    };

    networks = {
      "30-wg0" = {
        matchConfig.Name = "wg0";

        networkConfig = {
          Address = "192.168.2.${config.network-id}/24";
        };
      };
    };
  };
}
