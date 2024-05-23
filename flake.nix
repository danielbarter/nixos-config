{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    hosts.url = "github:StevenBlack/hosts";

    # unify nixpkgs across inputs
    hosts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      hosts,
    }@outputs-args:
    {

      nixosConfigurations =
        let
          core-modules = [
            ./base.nix
            ./networking.nix
            ./users.nix
            ./nix-config.nix
          ];

          # pass through flake outputs
          flake-args =
            { gui }:
            {
              flake-outputs-args = outputs-args;
              flake = self;
              inherit gui;
            };
        in
        {
          jasper = nixpkgs.lib.nixosSystem {
            specialArgs = flake-args { gui = true; };
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./jasper.nix
              ./sway-gui.nix
              ./intel-gpu.nix
            ];
          };

          punky = nixpkgs.lib.nixosSystem {
            specialArgs = flake-args { gui = false; };
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./punky.nix
              hosts.nixosModule
              {
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

          rupert = nixpkgs.lib.nixosSystem {
            specialArgs = flake-args { gui = true; };
            system = "x86_64-linux";
            modules = core-modules ++ [ ./rupert.nix ];
          };

          x86_64-replicant = nixpkgs.lib.nixosSystem {
            specialArgs = flake-args { gui = true; };
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              # we are probably going to be running on some intel chip,
              # so make sure that we have VA-API drivers so firefox is happy
              ./intel-gpu.nix
              ./sway-gui.nix
            ];
          };

          aarch64-replicant = nixpkgs.lib.nixosSystem {
            specialArgs = flake-args { gui = false; };
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              {
                nixpkgs.buildPlatform.system = "x86_64-linux";
                nixpkgs.hostPlatform.system = "aarch64-linux";
              }
            ];
          };
        };

      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };

          x86_64-vm =
            image:
            pkgs.writeScriptBin "x86_64-run-nixos-vm" ''
              #!${pkgs.runtimeShell}
              cp ${image}/image.raw /tmp/image.raw
              chmod +w /tmp/image.raw
              ${pkgs.qemu}/bin/qemu-kvm \
              -smp $(nproc) \
              -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
              -drive file=/tmp/image.raw,format=raw \
              -nographic \
              -m 8G
            '';

          aarch64-vm =
            image:
            let
              drive-flags = "format=raw,readonly=on";
              efi-flash = "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw";
            in
            pkgs.writeScriptBin "aarch64-run-nixos-vm" ''
              #!${pkgs.runtimeShell}
              cp ${image}/image.raw /tmp/image.raw
              chmod +w /tmp/image.raw
              ${pkgs.qemu}/bin/qemu-system-aarch64 \
              -machine virt \
              -cpu cortex-a57 \
              -m 2G \
              -smp 4 \
              -nographic \
              -drive if=pflash,file=${efi-flash},${drive-flags} \
              -drive file=/tmp/image.raw,${drive-flags}
            '';
        in
        {

          # before building run ./utils/pack_etc_nixos.sh
          x86_64-replicant-image = self.nixosConfigurations.x86_64-replicant.config.system.build.image;
          x86_64-replicant-vm = x86_64-vm self.packages."x86_64-linux".x86_64-replicant-image;
          aarch64-replicant-image = self.nixosConfigurations.aarch64-replicant.config.system.build.image;
          aarch64-replicant-vm = aarch64-vm self.packages."x86_64-linux".aarch64-replicant-image;
        };
    };
}
