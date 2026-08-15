{
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

    # use resolved for dns management
    # since it works more seamlessly with systemd-networkd
    services.resolved.enable = true;
    services.resolved.settings.Resolve = {

      # dnssec randomly failing sometimes
      # with DNSSEC validation failed: no-signature
      DNSSEC = false;

      MulticastDNS = true;

      # if not set, resolved defaults to its own list
      FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
}
