let network-ids = import ./network-ids.nix;
in [
  {
    PublicKeyFile = "/cold/public/wireguard/punky";
    AllowedIPs = [ "192.168.2.${network-ids.punky}" ];
    Endpoint = [ "hobiehomelab.duckdns.org:51821"];
  }
  
  {
    PublicKeyFile = "/cold/public/wireguard/phone";
    AllowedIPs = [ "192.168.2.${network-ids.phone}" ];
  }
  
  {
    PublicKeyFile = "/cold/public/wireguard/blaze";
    AllowedIPs = [ "192.168.2.${network-ids.blaze}" ];
    Endpoint = [ "hobiehomelab.duckdns.org:51820"];
  }
]
