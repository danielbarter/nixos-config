{pkgs, ...}:

{
  nix = {
    settings = {
      substituters = [
        "http://rupert:5000"
        "https://cache.nixos.org/"
      ];

      trusted-public-keys = [
        (builtins.readFile "/etc/nixos/secrets/binary-cache/cache-pub-key.pem")
      ];
    };
  };

  networking.interfaces."wlan0".useDHCP = true;

  services.logind.lidSwitch = "suspend";

  # make udev rules for backlight
  programs.light.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.logind = {
    killUserProcesses = false;
    extraConfig = "HandlePowerKey=suspend";
  };

  # gammastep systemd service
  systemd.user.services.kanshi = {
    description = "kanshi daemon";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c /etc/nixos/dotfiles/sway/config_kanshi'';
    };
  };

}
