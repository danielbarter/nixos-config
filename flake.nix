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
    nixpkgs.url = "github:NixOs/nixpkgs/3870b7fece9e0b946fafb0fa21e11d7228a752a7";
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
    {

      nixosConfigurations = import ./nixos-configurations.nix { inherit nixpkgs hosts;};
      packages."x86_64-linux" = import ./images.nix {
        nixosConfigurations = self.nixosConfigurations;
        inherit nixpkgs;
      };
    };
}
