{pkgs, ...}:

{
  nix = {
    settings = {
      substituters = [
        # "http://rupert:5000"
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = [
        (builtins.readFile "/etc/nixos/secrets/binary-cache/cache-pub-key.pem")
      ];
    };
  };

  systemd.network = {
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

  services.logind.lidSwitch = "suspend";

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware = {
    # steam client needs 32 bit video/audio drivers to start
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # kernel module for switch pro controller
  boot.kernelModules = [ "hid-nintendo" ];

  services.logind = {
    extraConfig = "HandlePowerKey=suspend";
  };
}
