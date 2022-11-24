# nix-shell -p nixos-generators
# nixos-generate --format iso --configuration /etc/nixos/iso.nix -o /tmp/result

{pkgs, modulesPath, lib, ... }: {

  environment.systemPackages = with pkgs; [
    git
    gnupg
  ];

  # enable gpg
  programs.gnupg.agent.enable = true;

  # enable ssh
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/jAy9NJtm0TH4gCVxcjDd9kpsHq+sbpUNGZxk2sghF75ZEmoqAXS0WaehHzf38cV2j0nq+kx7lEs5tCGyO80JJrkXlao72Ghyw8D1EOOSQp9OAqNxG44T809zxNHX8prINI36FSpfRrY7wU08CXa3LcJvqRjTBtS/qKvhkR0bPl2iHuTHDFtorHCpe3Hwbsa2wWDZDxiTTFouUA1IEH83QE01xu/BvhKVAIwKT8okbSf/jw+jE60JIl74CLaTI0losbB4TLDxBjPVGtXcnL+S/146keA+KVeyZ5EhZ1PEUSqYbtVg+tf59ekEgx9xPiWvzwv1i4g2qxf3q+Elqqu+MH9db5h+ma9ykWO3jZoQLwV1Bm0hmDq6FyN5/6y8ZAA5kn8JDzVd6iw163KUwCzEpksbfljAiknsRU2cjAbJFveciMT/6PRhl1Ln0tVoVkapynTL5PWsaQKOyf7Uj+B5uVMRv9XJDpLv4pYOS8nV6veZqETKXYQLFpI70DSWrSro/bQ1xOKlh/PHrhcbh3x+cpO7bOGcXOtWdS9w+ffoMZjCZLNnQdTCjkJ9XA+CTUcOoGYFNAPaWffX63CWbqUv5X0Ll7zDv7y0z7CQcWmICFpq5CQezvdeMsh17d970X/EdDrVuNBWItCMRbaXpXP4Fm715UKPTs0qZSVUJTLXPw== danielbarter@gmail.com"
  ];

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

  # boot.kernelPackages = pkgs.linuxPackages_latest;

  security.sudo.wheelNeedsPassword = false;
}
