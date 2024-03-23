{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "git+file:///home/danielbarter/nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators-unstable.url = "github:nix-community/nixos-generators";

    hosts.url = "github:StevenBlack/hosts";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    # unify nixpkgs across inputs
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    hosts.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
      self, nixpkgs, nixpkgs-unstable, nixos-generators,
      nixos-generators-unstable, hosts, emacs-overlay
  } @ outputs-args:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
          ./nix-config.nix
        ];

        flake-outputs-args-passthrough = {
          flake-outputs-args = outputs-args;
          flake = self;
        };

        platform = {build, host}: {...}: {
          nixpkgs.buildPlatform.system = build;
          nixpkgs.hostPlatform.system = host;
        };

    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          specialArgs = flake-outputs-args-passthrough;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./sway-gui.nix
              ./intel-gpu.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem rec {
          specialArgs =  flake-outputs-args-passthrough;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./punky.nix
              hosts.nixosModule {
                networking.stevenBlackHosts = {
                  enable = true;
                  blockFakenews = true;
                  blockGambling = true;
                  blockPorn = true;
                  blockSocial = true;
                };
              }
              ./intel-gpu.nix
            ];
        };

        rupert = nixpkgs.lib.nixosSystem rec {
          specialArgs =  flake-outputs-args-passthrough;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./rupert.nix
            ];
        };
      };

      packages."aarch64-linux" =
        let
          emacs-pkgs = import nixpkgs {
            system = "x86_64-linux";
            crossSystem = "aarch64-linux";
            overlays = [ emacs-overlay.overlays.default ];
          };
        in
          {
            emacs = emacs-pkgs.emacs-git.override {
              withPgtk = true;
            };
          };

      packages."x86_64-linux" =
        let
          emacs-pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ emacs-overlay.overlays.default ];
          };

          pkgs = import nixpkgs { system = "x86_64-linux"; };


          x86_64-vm = iso: pkgs.writeScriptBin "x86_64-run-nixos-vm" ''

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
          in pkgs-x86_64.writeScriptBin "aarch64-run-nixos-vm" ''

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

          # before building run ./utils/pack_etc_nixos.sh
          replicant-iso = nixos-generators.nixosGenerate rec {
            specialArgs = flake-outputs-args-passthrough;
            format = "iso";
            system = "x86_64-linux";
            modules = core-modules ++ [
              # we are probably going to be running on some intel chip,
              # so make sure that we have VA-API drivers so firefox is happy
              ./intel-gpu.nix
              ./replicant.nix
              ./sway-gui.nix
            ];
          };

          replicant-vm = x86_64-vm self.packages."x86_64-linux".replicant-iso;

          # before building run ./utils/pack_etc_nixos.sh
          aarch64-replicant-iso = nixos-generators-unstable.nixosGenerate rec {
            specialArgs = flake-outputs-args-passthrough;
            format = "iso";
            system = "x86_64-linux";
            modules = [
              ./base.nix
              ./networking.nix
              ./users.nix
              ./replicant.nix
              ./sway-gui.nix
              (platform {build = system; host = "aarch64-linux";})
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
