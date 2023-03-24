{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    hosts.url = github:StevenBlack/hosts;
    emacs-overlay.url = github:nix-community/emacs-overlay;
  };

  outputs = { self, nixpkgs, hosts, emacs-overlay }:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
          ./lingering.nix
          ./pass.nix
          ./home-setup.nix
          ./emacs.nix
        ];
        special-args = system: {
          inherit nixpkgs emacs-overlay system;};
    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          specialArgs = special-args system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./gui.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem rec {
          specialArgs = special-args system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./punky.nix
              hosts.nixosModule { networking.stevenBlackHosts.enable = true; }
            ];
        };

        rupert = nixpkgs.lib.nixosSystem rec {
          specialArgs = special-args system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./rupert.nix
            ];
        };
      };
    };
}
