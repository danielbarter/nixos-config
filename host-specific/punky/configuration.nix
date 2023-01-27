{config, pkgs, ...}:
{

  networking.hostName = "punky";

  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/etc/nixos/secrets/binary-cache/cache-priv-key.pem";
  };

    # serve DNS stub on local network
  services.resolved.extraConfig = ''
       DNSStubListenerExtra=192.168.1.10
  '';




  # these get put into /etc/hosts
  networking = {
    hosts = {
      "192.168.1.1" = [ "asusmain" ];
      "192.168.1.2" = [ "asusaux" ];
      "192.168.1.10" = [ "rupert" ];
      "192.168.1.11" = [ "rupertwireless" ];
      "192.168.1.12" = [ "punky" ];
      "192.168.1.13" = [ "punkywireless" ];
    };

    # DNS used by resolved. resolvectl status
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

}
