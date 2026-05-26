# flake inputs can be overriden eg
# --override-input nixpkgs /home/danielbarter/nixpkgs
#
# substituters can be overriden with
# --option substituters ssh://nix-ssh@punky.lan
# 
# to rebuild, pulling image from punky:
# sudo nixos-rebuild --impure --option substituters ssh://nix-ssh@punky.lan switch
#
# copy closure of store path from substituter
# nix-store --realise --substituters ssh://nix-ssh@punky.lan <path>
{
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/release-26.05";
    hosts.url = "github:StevenBlack/hosts";

    # unify nixpkgs across inputs
    hosts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      hosts,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      nixpkgsSource = pkgs.applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgs;
        patches = [ ./patches/cross_build.patch ];
      };
    in
    {

      # In this file, nixpkgs is the flake input object. Past this boundary,
      # nixpkgs is the patched nixpkgs source tree path.
      nixosConfigurations = import ./nixos-configurations.nix {
        nixpkgs = nixpkgsSource;
        hosts = hosts.nixosModule;
      };
      packages.${system} = import ./images.nix {
        nixosConfigurations = self.nixosConfigurations;
        nixpkgs = nixpkgsSource;
      };
    };
}
