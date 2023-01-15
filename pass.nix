{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (pass.withExtensions (exts: [exts.pass-otp]))
    zbar # QRcode reader
  ];

  # enable gpg
  programs.gnupg.agent.enable = true;
}
