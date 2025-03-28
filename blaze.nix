# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{


  imports = [
    ./wireguard-interface.nix
  ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };


  systemd.network.networks = {

    # LAN interface, with a DHCP server
    "40-lan" = {
      matchConfig = {
        Name = "eno1";
      };
      networkConfig = {
        DHCPServer = "yes";
        Address = "192.168.1.${config.network-id}/24";
      };

      dhcpServerConfig = {
        ServerAddress = "192.168.1.${config.network-id}/24";
        PoolOffset = 100;
        PoolSize = 128;
        DNS = "192.168.1.${config.network-id}";
        EmitRouter= true;
        Router="192.168.1.${config.network-id}";
      };
    };

    # WAN interface with DHCP
    "40-wan" = {
      matchConfig = {
        Name = "eno0";
      };

      networkConfig = {
        DHCP = "ipv4";
        LLDP = "no";
      };
    };
  };

  # serve DNS stub on local network
  services.resolved.extraConfig = ''
    DNSStubListenerExtra=192.168.1.${config.network-id}
    DNSStubListenerExtra=192.168.2.${config.network-id}
  '';

  # ddns update for LAN
  systemd.services.ddns-update = let
  ddns-update = (pkgs.callPackage ./ddns-update.nix {});
  in {
    wantedBy = [ "timers.target" ];
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${ddns-update}/bin/ddns_update --token_file /etc/nixos/secrets/duckdns_token --domain hobiehomelab --wan_interface eno0
        '';
    };
    unitConfig = {
      PartOf = [ "timers.target" ];
    };
  };

  systemd.timers.ddns-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "10min";
    };
  };



  networking = let network-ids = import ./network-ids.nix;
   in {
    nftables = {
      enable = true;
      ruleset = ''
      define DEV_WAN = "eno0"
      define DEV_LAN = "eno1"
      define PRIORITY = 100
      define NET_LAN = 192.168.1.0/24
      table inet filter {
        chain input {
          type filter hook input priority $PRIORITY; policy drop;
          jump common
        }

        chain forward {
          type filter hook forward priority $PRIORITY; policy drop;
          jump common
        }

        chain common {
          # don't drop packets from LAN or wireguard
          iifname { $DEV_LAN, lo, wg0 } accept

          # allow returning traffic from connections initiated in LAN
          ct state vmap { established : accept, related : accept, invalid : drop }

          # accept ipv6 control packets
          # icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept

          # accept wireguard packets
          udp dport {51820, 51821} accept

          # log any packets we are dropping
          # log prefix "nft drop: "
        }
      }

      table ip nat {

        chain prerouting {
          type nat hook prerouting priority $PRIORITY; policy accept;
          udp dport 51821 dnat to 192.168.1.12:51820

        }
        chain postrouting {
          type nat hook postrouting priority $PRIORITY; policy accept;
          ip saddr $NET_LAN oifname $DEV_WAN masquerade
        }
      }
      '';
    };

    hostName = "blaze";

    # DNS used by resolved. resolvectl status
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    hosts = {
      "192.168.1.${network-ids.rupert}" = [ "rupert.lan" ];
      "192.168.2.${network-ids.rupert}" = [ "rupert.wg" ];
      
      "192.168.1.${network-ids.punky}" = [ "punky.lan" ];
      "192.168.2.${network-ids.punky}" = [ "punky.wg" ];
      
      "192.168.1.${network-ids.jasper}" = [ "jasper.lan" ];
      "192.168.2.${network-ids.jasper}" = [ "jasper.wg" ];

      "192.168.1.${network-ids.blaze}" = [ "blaze.lan" ];
      "192.168.2.${network-ids.blaze}" = [ "blaze.wg" ];

      "192.168.1.${network-ids.asus2}" = [ "asus2.lan" ];
      "192.168.1.${network-ids.asus3}" = [ "asus3.lan" ];
    };

    stevenBlackHosts = {
      enable = true;
      blockFakenews = true;
      blockGambling = true;
      blockPorn = true;
      blockSocial = true;
    };
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/d0cd1c8b-869e-4dee-ae4f-c47901484d6f";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/12CE-A600";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "25.05"; # Did you read the comment?

}

