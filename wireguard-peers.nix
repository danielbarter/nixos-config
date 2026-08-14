let network-ids = import ./network-ids.nix;
in [ 
  {
    PublicKeyFile = "/cold/public/wireguard/phone";
    AllowedIPs = [ "192.168.2.${network-ids.phone}" ];
  }  
]
