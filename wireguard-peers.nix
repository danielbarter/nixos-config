[
  {
    PublicKey = (builtins.readFile ./public/wireguard/punky);
    AllowedIPs = [ "192.168.2.12" ];
  }
  
  {
    PublicKey = (builtins.readFile ./public/wireguard/jasper);
    AllowedIPs = [ "192.168.2.13" ];
  }
]
