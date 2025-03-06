[
  {
    PublicKey = (builtins.readFile ./public/wireguard/punky);
    AllowedIPs = [ "192.168.2.12" ];
    Endpoint = [ "192.168.1.12:51820"];
  }
  
  {
    PublicKey = (builtins.readFile ./public/wireguard/jasper);
    AllowedIPs = [ "192.168.2.13" ];
    Endpoint = [ "192.168.1.13:51820"];
  }
]
