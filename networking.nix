{
  config,
  pkgs,
  flake,
  ...
}:
{
  services.resolved = {
    # use resolved for dns management
    enable = true;

    # dnssec randomly failing sometimes
    # with DNSSEC validation failed: no-signature
    dnssec = "false";

    # protocol used to route single label names.
    # doesn't work great on small home networks using only ipv4
    # see man 8 systemd-resolved
    llmnr = "false";

    # if not set, resolved defaults to its own list
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

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

    # disable various default nixos networking components
    dhcpcd.enable = false;
    firewall.enable = false;
    useDHCP = false;

    useNetworkd = true;
    wireless.iwd = {

      # run developer mode of iwd
      # package = flake.packages."${system}".iwd-with-developer-mode;
      enable = true;
      settings = {
        General = {
          # attempt to find a better AP every 10 seconds (default is 60)
          RoamRetryInterval = "10";
        };
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  programs.ssh.extraConfig = builtins.readFile ./dotfiles/ssh/config;

  environment.systemPackages = with pkgs; [
    iw # linux tool for managing wireless networks
    wget
  ];
}
