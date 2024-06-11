{
  pkgs,
  config,
  ...
}:
{
  environment.systemPackages =
    let sway-enabled = config.programs.sway.enable;
    in [
      pkgs.tmux # terminal multiplexer
      pkgs.git
      pkgs.file
      pkgs.htop
      # we use dbus-python for the sway status bar
      (if sway-enabled then (pkgs.python3.withPackages (p: [ p.dbus-python ])) else pkgs.python3)
      pkgs.zip
      pkgs.unzip
      pkgs.fzf # fuzzy searcher
      (if sway-enabled then pkgs.emacs29-pgtk else pkgs.emacs29-nox)

      (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))

      pkgs.man-pages # linux programmers man pages
      pkgs.man-pages-posix # posix man pages
    ];

}
