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
    services.resolved = {
      # use resolved for dns management
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

    # enable systemd networking for all hosts
    # actual networkd config is host specific
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
    };

    # Enable the OpenSSH daemon.
    services.openssh = {
      # store public keys in a single location
      authorizedKeysInHomedir = false;
    
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };

    programs.ssh.extraConfig = ''
    Host *
        IdentityFile /etc/nixos/secrets/ssh/id_rsa
    '';
  };
}
