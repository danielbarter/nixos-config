{ config, pkgs, ... }:

{
  # dnssec randomly failing sometimes
  # with DNSSEC validation failed: no-signature
  services.resolved.dnssec = "false";

  # more reliable replacement for nscd
  services.nscd.enableNsncd = true;

  # enable systemd networking for all hosts
  # actual networkd config is host specific
  systemd.network.enable = true;

  # better networkd wait-online defaults for PCs
  # man systemd-networkd-wait-online 8
  systemd.network.wait-online.anyInterface = true;
  systemd.network.wait-online.timeout = 0;

  # give wireless cards time to turn on
  systemd.services.iwd.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

  networking = {

    # these get put into /etc/hosts
    hosts = {
      "192.168.1.1" = [ "asusmain" ];
      "192.168.1.2" = [ "asusaux" ];
      "192.168.1.10" = [ "rupert" ];
      "192.168.1.11" = [ "rupertwlan" ];
    };

    # disable various default nixos networking components
    dhcpcd.enable = false;
    firewall.enable = false;
    useDHCP = false;

    useNetworkd = true;
    wireless.iwd = {
      enable = true;
    };

    # these get put into /etc/resolved.conf
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  programs.ssh.extraConfig = builtins.readFile ./dotfiles/ssh/config;



  environment.systemPackages = with pkgs; [
    iw                  # linux tool for managing wireless networks
    wget
  ];
}