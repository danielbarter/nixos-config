# nix-shell -p nixos-generators
# nixos-generate --format iso --configuration /etc/nixos/iso.nix -o /tmp/result

{pkgs, modulesPath, lib, ... }: {



  imports = [
      "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  services.resolved.dnssec = "false";
  systemd.services.iwd.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

  systemd.network.wait-online.anyInterface = true;
  systemd.network.wait-online.timeout = 0;

  systemd.network = {
    enable = true;
    networks = {
      "40-wlan0" = {
        matchConfig = {
          Name = "wlan0";
        };

        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };

  networking = {
    hostName = "iso";

    # disable various default nixos networking components
    dhcpcd.enable = false;
    firewall.enable = false;
    useDHCP = false;

    useNetworkd = true;
    wireless.enable = false;
    wireless.iwd = {
      enable = true;
    };

    # these get put into /etc/resolved.conf
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

  };


  boot.kernelPackages = pkgs.linuxPackages_latest;

  security.sudo.wheelNeedsPassword = false;
}
