{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

      nixosConfigurations =
        let
          core-modules = [
            ./base.nix
            ./packages.nix
            ./networking.nix
            ./users.nix
            ./nix-config.nix
            { nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ]; }
          ];
        in
        {
          jasper = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./jasper.nix
              ./sway-gui.nix
              ./sound.nix
              ./intel-gpu.nix
            ];
          };

          punky = nixpkgs.lib.nixosSystem {
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
              ./sound.nix
            ];
          };

          rupert = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = core-modules ++ [ ./rupert.nix ./sound.nix ];
          };

          x86_64-replicant = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              # we are probably going to be running on some intel chip,
              # so make sure that we have VA-API drivers so firefox is happy
              ./intel-gpu.nix
              ./sway-gui.nix
              ./sound.nix
            ];
          };

          aarch64-replicant-cross = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              {
                nixpkgs.buildPlatform.system = "x86_64-linux";
                nixpkgs.hostPlatform.system = "aarch64-linux";
              }
            ];
          };

          aarch64-replicant = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              ./sway-gui.nix
              ./sound.nix
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
              cp ${image}/image.raw /dev/shm/image.raw
              chmod +w /dev/shm/image.raw
              ${pkgs.qemu}/bin/qemu-kvm \
              -smp $(nproc) \
              -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
              -drive file=/dev/shm/image.raw,format=raw \
              -nographic \
              -m 8G
              rm /dev/shm/image.raw
            '';

          aarch64-vm =
            image:
            let
              drive-flags = "format=raw,readonly=on";
              efi-flash = "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw";
            in
            pkgs.writeScriptBin "aarch64-run-nixos-vm" ''
              #!${pkgs.runtimeShell}
              cp ${image}/image.raw /dev/shm/image.raw
              chmod +w /dev/shm/image.raw
              ${pkgs.qemu}/bin/qemu-system-aarch64 \
              -machine virt \
              -cpu cortex-a57 \
              -m 2G \
              -smp 4 \
              -nographic \
              -drive if=pflash,file=${efi-flash},${drive-flags} \
              -drive file=/dev/shm/image.raw,${drive-flags}
              rm /dev/shm/image.raw
            '';
        in
        {

          # before building run ./utils/pack_etc_nixos.sh
          x86_64-replicant-image = self.nixosConfigurations.x86_64-replicant.config.system.build.image;
          x86_64-replicant-vm = x86_64-vm self.packages."x86_64-linux".x86_64-replicant-image;
          aarch64-replicant-image = self.nixosConfigurations.aarch64-replicant.config.system.build.image;
          aarch64-replicant-vm = aarch64-vm self.packages."x86_64-linux".aarch64-replicant-image;
          aarch64-replicant-cross-image = self.nixosConfigurations.aarch64-replicant-cross.config.system.build.image;
          aarch64-replicant-cross-vm = aarch64-vm self.packages."x86_64-linux".aarch64-replicant-cross-image;

        };
    };
}
