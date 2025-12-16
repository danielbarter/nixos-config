{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.network-id = lib.mkOption {
    type = lib.types.str;
    default =  (import ./network-ids.nix).${config.networking.hostName};
    description = "id used for static IP: 192.168.1.x and wireguard network 192.168.2.x";
  };


  config = {

    # we use systemd-networkd on headless hosts
    systemd.network.enable = true;

    # better networkd wait-online defaults for PCs
    # man systemd-networkd-wait-online 8
    systemd.network.wait-online.anyInterface = true;
    systemd.network.wait-online.timeout = 0;

    networking = {
      # disable various default nixos networking components
      nat.enable = false;
      dhcpcd.enable = false;
      firewall.enable = false;
      useDHCP = false;
      useNetworkd = true;
      networkmanager.enable = false;
    };

    users.users = {
      # let systemd-networkd access files belonging to users, like public wireguard keys
      systemd-network = {
        extraGroups = [ "users" "wheel" ];
      };
    };

    # wireguard interface for headless machines
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
            Address = "192.168.2.${config.network-id}/24";
          };
        };
      };
    };
        
    services.resolved = {
      # use resolved for dns management
      # since it works more seamlessly with systemd-networkd
      enable = true;

      # dnssec randomly failing sometimes
      # with DNSSEC validation failed: no-signature
      dnssec = "false";

      # residential ISPs tend to provide
      # /64 ipv6 addresses, which makes
      # enabling ipv6 on LAN akward...
      # multicast dns protocols generally
      # expect a dual ipv4/6 network,
      # so disabling LLMNR
      llmnr = "false";

      # if not set, resolved defaults to its own list
      fallbackDns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
}
