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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOs/nixpkgs/release-26.05";
    hosts = {
      url = "github:StevenBlack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    voxtype = {
      url = "github:danielbarter/voice_to_text";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      hosts,
      voxtype,
      sops-nix
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # collect all .patch files in the patches folder and apply them to nixpkgs
      patchFiles = if builtins.pathExists ./patches then builtins.readDir ./patches else { };
      patches = builtins.map (name: ./patches + "/${name}") (
        builtins.filter (
          name:
          builtins.match ".*\\.patch" name != null
          && patchFiles.${name} == "regular"
        ) (builtins.attrNames patchFiles)
      );
      nixpkgsSource = pkgs.applyPatches {
        name = "nixpkgs";
        src = nixpkgs;
        inherit patches;
      };
    in
    {
      devShells.${system}.secrets = pkgs.mkShell {
        packages = with pkgs; [ age sops gnupg wireguard-tools jq python3 openssh ];
        shellHook = "umask 077";
      };

      # In this file, nixpkgs is the flake input object. Past this boundary,
      # nixpkgs is the patched nixpkgs source tree path.
      nixosConfigurations = import ./nixos-configurations.nix {
        nixpkgs = nixpkgsSource;
        hosts = hosts.nixosModule;
        voxtype = voxtype.nixosModules.default;
        sopsModule = sops-nix.nixosModules.sops;
      };
      packages.${system} = import ./images.nix {
        nixosConfigurations = self.nixosConfigurations;
        nixpkgs = nixpkgsSource;
      };
    };
}
