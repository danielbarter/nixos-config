let network-ids = import ./network-ids.nix;
in [
  {
    PublicKey = (builtins.readFile ./public/wireguard/punky);
    AllowedIPs = [ "192.168.2.${network-ids.punky}" ];
    Endpoint = [ "punkymeow.duckdns.org:51820"];
  }
  
  {
    PublicKey = (builtins.readFile ./public/wireguard/phone);
    AllowedIPs = [ "192.168.2.${network-ids.phone}" ];
  }
]
