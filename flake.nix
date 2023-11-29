{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
    hosts.url = "github:StevenBlack/hosts";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    # unify nixpkgs across inputs
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    hosts.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self, nixpkgs, nixpkgs-unstable, nixos-generators, hosts, emacs-overlay
  }:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
          ./lingering.nix
          ./pass.nix
          ./home-setup.nix
          ./emacs.nix
          ./manpages.nix
        ];
        special-args = system: {
          inherit self nixpkgs nixpkgs-unstable emacs-overlay system;};
    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          specialArgs = special-args system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./sway-gui.nix
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

      packages."x86_64-linux" = {
        # build using ./utils/build_replicant_iso.sh
        # qemu-kvm -smp 8 -cdrom /tmp/nixos.iso -nographic -m 8G
        replicant-iso = nixos-generators.nixosGenerate rec {
          specialArgs = special-args system;
          format = "iso";
          system = "x86_64-linux";
          modules = core-modules ++ [
            ./replicant.nix
            ./sway-gui.nix
          ];
        };

        aarch64-linux-iso = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "iso";
            modules = [ ./aarch64-linux-base-module.nix  ];
        };

        aarch64-linux-vm =
          let pkgs-x86_64 = import nixpkgs { system = "x86_64-linux"; };
              pkgs-aarch64 = import nixpkgs { system = "aarch64-linux"; };
              drive-flags = "format=raw,readonly=on";
          in pkgs-x86_64.writeScriptBin "run-nixos-vm-aarch64" ''

          #!${pkgs-x86_64.runtimeShell} \
          ${pkgs-x86_64.qemu_full}/bin/qemu-system-aarch64 \
          -machine virt \
          -cpu cortex-a57 \
          -m 2G \
          -nographic \
          -drive if=pflash,file=${pkgs-aarch64.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw,${drive-flags} \
          -drive file=${self.packages."x86_64-linux".aarch64-linux-iso}/iso/nixos.iso,${drive-flags}
          '';
     };
    };
}
