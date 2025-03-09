let network-ids = import ./network-ids.nix;
in [
  {
    PublicKeyFile = "/etc/nixos/public/wireguard/punky";
    AllowedIPs = [ "192.168.2.${network-ids.punky}" ];
    Endpoint = [ "hobiehomelab.duckdns.org:51820"];
  }
  
  {
    PublicKeyFile = "/etc/nixos/public/wireguard/phone";
    AllowedIPs = [ "192.168.2.${network-ids.phone}" ];
  }

  {
    PublicKeyFile = "/etc/nixos/public/wireguard/replicant";
    AllowedIPs = [ "192.168.2.${network-ids.replicant}" ];
  }
]
