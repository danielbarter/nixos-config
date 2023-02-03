{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }: {

    nixosConfigurations = {
      jasper = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit nixpkgs; };
        system = "x86_64-linux";
        modules =
          [
            ./base.nix
            ./networking.nix
            ./emacs.nix
            ./users.nix
            ./lingering.nix
            ./pass.nix
            ./home-setup.nix
            ./jasper.nix
            ./gui.nix
          ];
      };

      punky = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit nixpkgs; };
        system = "x86_64-linux";
        modules =
          [
            ./base.nix
            ./networking.nix
            ./emacs.nix
            ./users.nix
            ./lingering.nix
            ./pass.nix
            ./home-setup.nix
            ./punky.nix
          ];
      };

      rupert = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit nixpkgs; };
        system = "x86_64-linux";
        modules =
          [
            ./base.nix
            ./networking.nix
            ./emacs.nix
            ./users.nix
            ./lingering.nix
            ./pass.nix
            ./home-setup.nix
            ./rupert.nix
          ];
      };
    };
  };
}
