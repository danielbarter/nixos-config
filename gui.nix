{
  pkgs,
  ...
}:
{
  # firefox integration
  programs.firefox.enable = true;


  # enable cosmic
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  hardware.bluetooth.enable = true;

  environment.systemPackages = [
    pkgs.alacritty
    pkgs.zathura
    pkgs.wl-clipboard
  ];
  
}
