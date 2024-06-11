{
  pkgs,
  ...
}:
{
  environment.systemPackages = [
      pkgs.binutils # objdump, readelf and c++filt
      pkgs.strace
      pkgs.pciutils # lspci
      pkgs.usbutils # lsusb
      pkgs.nmap
      pkgs.radare2
      pkgs.direnv
      pkgs.gdb
      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.cmake # cmake autocomplete and emacs mode.

    ];

}
