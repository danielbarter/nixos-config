{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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
  } @ outputs-args:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
        ];

        flake-outputs-args-passthrough = system: {
          flake-outputs-args = outputs-args;
          flake = self;
          inherit system;
        };

        platform = {build, host}: {...}: {
          nixpkgs.buildPlatform.system = build;
          nixpkgs.hostPlatform.system = host;
        };

    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          specialArgs = flake-outputs-args-passthrough system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./sway-gui.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem rec {
          specialArgs =  flake-outputs-args-passthrough system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./punky.nix
              hosts.nixosModule { networking.stevenBlackHosts.enable = true; }
            ];
        };

        rupert = nixpkgs.lib.nixosSystem rec {
          specialArgs =  flake-outputs-args-passthrough system;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./rupert.nix
            ];
        };
      };

      packages."x86_64-linux" =
        let
          emacs-pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ emacs-overlay.overlays.default ];
          };

          pkgs = import nixpkgs { system = "x86_64-linux"; };


          x86_64-vm = iso: pkgs.writeScriptBin "run-nixos-vm-x86_64" ''

          #!${pkgs.runtimeShell} \
          ${pkgs.qemu_full}/bin/qemu-kvm \
          -smp $(nproc) \
          -cdrom ${iso}/iso/nixos.iso \
          -nographic \
          -m 8G

          '';

          aarch64-vm = iso: let
            pkgs-x86_64 = import nixpkgs { system = "x86_64-linux"; };
            pkgs-aarch64 = import nixpkgs { system = "aarch64-linux"; };
            drive-flags = "format=raw,readonly=on";
          in pkgs-x86_64.writeScriptBin "run-nixos-vm-aarch64" ''

            #!${pkgs-x86_64.runtimeShell} \
            ${pkgs-x86_64.qemu_full}/bin/qemu-system-aarch64 \
            -machine virt \
            -cpu cortex-a57 \
            -m 2G \
            -smp 4 \
            -nographic \
            -drive if=pflash,file=${pkgs-aarch64.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw,${drive-flags} \
            -drive file=${iso}/iso/nixos.iso,${drive-flags}

            '';


        in {

          emacs = emacs-pkgs.emacs-git.override {
            withPgtk = true;
          };

          iwd-with-developer-mode = pkgs.iwd.overrideAttrs (final: previous: {
            patches = ( previous.patches or [] ) ++ [
              "${self.outPath}/patches/iwd_developer_mode.patch"
            ];
          });

          # build using ./utils/build_replicant_iso.sh
          # qemu-kvm -smp $(nproc) -cdrom /tmp/nixos.iso -nographic -m 8G
          replicant-iso = nixos-generators.nixosGenerate rec {
            specialArgs = flake-outputs-args-passthrough system;
            format = "iso";
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              ./sway-gui.nix
            ];
          };

          aarch64-minimal-iso = nixos-generators.nixosGenerate rec {
              system = "x86_64-linux";
              format = "iso";
              modules = [
                ./minimal-base.nix
                (platform {build = system; host = "aarch64-linux";})
              ];
          };

          aarch64-minimal-vm = aarch64-vm self.packages."x86_64-linux".aarch64-minimal-iso;

          x86_64-minimal-iso = nixos-generators.nixosGenerate rec {
              system = "x86_64-linux";
              format = "iso";
              modules = [
                ./minimal-base.nix
              ];
          };

          x86_64-minimal-vm = x86_64-vm self.packages."x86_64-linux".x86_64-minimal-iso;
        };
    };
}
