{
  pkgs,
  modulesPath,
  config,
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
    "${modulesPath}/profiles/clone-config.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  boot.isNspawnContainer = true;
  boot.isContainer = true;
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


  system.stateVersion = "25.11";
  users.users.root.hashedPassword = "";
  services.getty.autologinUser = "root";


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

    # Some container managers like lxc need these
    extraCommands =
      let
        script = pkgs.writeScript "extra-commands.sh" ''
          rm etc
          mkdir -p proc sys dev etc
        '';
      in
      script;
  };

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store in the Nix
    # database.
    if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
      rm /nix-path-registration
    fi

    # nixos-rebuild also requires a "system" profile
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
  '';

  # Install new init script
  system.activationScripts.installInitScript = ''
    ln -fs $systemConfig/init /init
  '';  
}
