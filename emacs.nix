{ config, pkgs, nixpkgs, emacs-overlay, ... }:

let pkgs-emacs-overlay-resolver = { nixpkgs, emacs-overlay }:
      import nixpkgs {
        system = "x86_64-linux";
        overlays = [ emacs-overlay.overlays.default ];
      };

    emacs-pkgs = (pkgs-emacs-overlay-resolver {inherit nixpkgs emacs-overlay;});

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
