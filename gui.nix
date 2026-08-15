{
  pkgs,
  ...
}:
{
  # Let NetworkManager pass per-link DNS and LLMNR configuration to
  # systemd-resolved on graphical hosts.
  networking.networkmanager = {
    dns = "systemd-resolved";
    settings.connection.llmnr = 2;
  };

  services.resolved = {
    enable = true;
    settings.Resolve.LLMNR = true;
  };

  # LLMNR normally uses UDP and falls back to TCP for oversized responses.
  networking.firewall = {
    allowedUDPPorts = [ 5355 ];
    allowedTCPPorts = [ 5355 ];
  };

  # firefox integration
  programs = {
    firefox.enable = true;
    steam.enable = true;
  };

  # enable cosmic
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  hardware.bluetooth.enable = true;

  environment.systemPackages = [
    pkgs.alacritty
    pkgs.zathura
    pkgs.wl-clipboard
    pkgs.xremap.cosmic
  ];
  
}
