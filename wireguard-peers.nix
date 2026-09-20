let network-ids = import ./network-ids.nix;
in [ 
  {
    PublicKeyFile = ./keys/wireguard/phone.pub;
    AllowedIPs = [ "192.168.2.${network-ids.phone}" ];
  }  
]
