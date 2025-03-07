let network-ids = import ./network-ids.nix;
in [
  {
    PublicKey = (builtins.readFile ./public/wireguard/punky);
    AllowedIPs = [ "192.168.2.${network-ids.punky}" ];
    Endpoint = [ "192.168.1.${network-ids.punky}:51820"];
  }
  
  {
    PublicKey = (builtins.readFile ./public/wireguard/jasper);
    AllowedIPs = [ "192.168.2.${network-ids.jasper}" ];
    Endpoint = [ "192.168.1.${network-ids.jasper}:51820"];
  }
]
