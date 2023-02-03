{ config, pkgs, pkgs-emacs-overlay, ... }:
{
  environment.systemPackages = with pkgs; [
    (pkgs-emacs-overlay.emacsGit.override {
      withPgtk = true;
    })
    # cmake autocomplete and emacs mode.
    cmake
    aspell
    aspellDicts.en
  ];

}
