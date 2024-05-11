{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hosts.url = "github:StevenBlack/hosts";

    # module for lenovo x13s
    # mainline support for x13s is constantly improving, so eventually,
    # this won't be necessary
    nixos-x13s.url = "git+https://codeberg.org/adamcstephens/nixos-x13s";

    # unify nixpkgs across inputs
    hosts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
      self, nixpkgs, hosts, nixos-x13s
  } @ outputs-args:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
          ./nix-config.nix
        ];


        # pass through flake outputs
        flake-args = {
          flake-outputs-args = outputs-args;
          flake = self;
        };

    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          specialArgs = flake-args;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./sway-gui.nix
              ./intel-gpu.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem rec {
          specialArgs =  flake-args;
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
          specialArgs =  flake-args;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./rupert.nix
            ];
        };

        x86_64-replicant = nixpkgs.lib.nixosSystem rec {
          specialArgs = flake-args;
          system = "x86_64-linux";
          modules = core-modules ++ [
            ./replicant.nix
            # we are probably going to be running on some intel chip,
            # so make sure that we have VA-API drivers so firefox is happy
            ./intel-gpu.nix
            ./sway-gui.nix
          ];
        };

        aarch64-replicant = nixpkgs.lib.nixosSystem  rec {
          specialArgs = flake-args;
          system = "aarch64-linux";
          modules = core-modules ++ [
            ./replicant.nix
            ./sway-gui.nix
            nixos-x13s.nixosModules.default {
              nixos-x13s.enable = true;
            }
            ];
        };
      };


      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };

          x86_64-vm = iso: pkgs.writeScriptBin "x86_64-run-nixos-vm" ''
            #!${pkgs.runtimeShell}
            ${pkgs.qemu_full}/bin/qemu-kvm \
            -smp $(nproc) \
            -cdrom ${iso}/iso/nixos.iso \
            -nographic \
            -m 8G
          '';

          aarch64-vm = iso: let
            drive-flags = "format=raw,readonly=on";
            efi-flash = "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw";
          in pkgs.writeScriptBin "aarch64-run-nixos-vm" ''
            #!${pkgs.runtimeShell}
            ${pkgs.qemu_full}/bin/qemu-system-aarch64 \
            -machine virt \
            -cpu cortex-a57 \
            -m 2G \
            -smp 4 \
            -nographic \
            -drive if=pflash,file=${efi-flash},${drive-flags} \
            -drive file=${iso}/iso/nixos.iso,${drive-flags}
            '';

        in {

          # before building run ./utils/pack_etc_nixos.sh
          x86_64-replicant-iso = self.nixosConfigurations.x86_64-replicant.config.system.build.isoImage;
          aarch64-replicant-iso = self.nixosConfigurations.aarch64-replicant.config.system.build.isoImage;
          x86_64-replicant-vm = x86_64-vm self.packages."x86_64-linux".x86_64-replicant-iso;
          aarch64-replicant-vm = aarch64-vm self.packages."x86_64-linux".aarch64-replicant-iso;
        };
    };
}
