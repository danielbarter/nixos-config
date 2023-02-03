{ config, pkgs, system, nixpkgs, emacs-overlay, ... }:

let pkgs-emacs-overlay-resolver = { nixpkgs, emacs-overlay, system }:
      import nixpkgs {
        inherit system;
        overlays = [ emacs-overlay.overlays.default ];
      };

    emacs-pkgs = (pkgs-emacs-overlay-resolver {inherit nixpkgs emacs-overlay system;});

in {
  environment.systemPackages = with pkgs; [
    (emacs-pkgs.emacsGit.override {
      withPgtk = true;
    })
    # cmake autocomplete and emacs mode.
    cmake
    aspell
    aspellDicts.en
  ];

}
