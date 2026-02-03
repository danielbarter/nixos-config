{
  pkgs,
  config,
  modulesPath,
  ...
}:

let
  pkgs2storeContents = map (x: {
    object = x;
    symlink = "none";
  });
in {

  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  boot.isNspawnContainer = true;
  console.enable = true;

  nix.extraOptions =
    let
      emptyFlakeRegistry = pkgs.writeText "flake-registry.json" (
        builtins.toJSON {
          flakes = [ ];
          version = 2;
        }
      );
    in
    ''
      flake-registry = ${emptyFlakeRegistry};
      experimental-features = nix-command flakes
    '';


  networking.hostName = "nixos";
  system.stateVersion = "25.11";
  users.users.root.initialHashedPassword = "";


  # Create the tarball
  system.build.tarball = pkgs.callPackage (pkgs.path + "/nixos/lib/make-system-tarball.nix") {
    contents = [
      {
        source = "${config.system.build.toplevel}/.";
        target = "./";
      }
    ];
    extraArgs = "--owner=0";

    # Add init script to image
    storeContents = pkgs2storeContents [
      config.system.build.toplevel
      pkgs.stdenv
    ];
  };

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store in the Nix
    # database.
    if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
      rm /nix-path-registration
    fi
  '';

  # Install init script
  system.activationScripts.installInitScript = ''
    ln -fs $systemConfig/init /init
  '';
}
