{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    stdman              # c++ stdlib man pages
    man-pages           # linux programmers man pages
    man-pages-posix     # posix man pages
  ];

  documentation = {
    dev.enable = true;
    enable = true;
    man.enable = true;
  };


}
