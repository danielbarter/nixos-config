{
  pkgs,
  ...
}:
{

  environment.systemPackages =
    let
    codex = import ./codex.nix {
      inherit pkgs;
    };
    in with pkgs; [
      tree
      tmux # terminal multiplexer
      git
      git-lfs
      file
      htop
      jq # json pretty print
      wget
      pciutils # lspci
      usbutils # lsusb
      nmap
      python3
      zip
      unzip
      fzf # fuzzy searcher
      helix
      aspell
      aspellDicts.en
      parted
      e2fsprogs
      wireguard-tools
      pass
      binutils # objdump, readelf and c++filt
      strace
      radare2
      direnv
      gdb
      man-pages # linux programmers man pages
      man-pages-posix # posix man pages
      ty # python type checker
      nixd
      codex
    ];
}
