{
  pkgs,
  config,
  modulesPath,
  ...
}:

let
  # Build the system tarball directly with the standard helper; no
  # docker-specific tweaks are needed when running under systemd-nspawn.
  tarball = pkgs.callPackage (modulesPath + "/../lib/make-system-tarball.nix") {
    contents = [
      {
        source = "${config.system.build.toplevel}/.";
        target = "./";
      }
    ];

    # Include the closure for the system derivation and stdenv so the store is
    # self-contained inside the tarball.
    storeContents = [
      {
        object = config.system.build.toplevel;
        symlink = "none";
      }
      {
        object = pkgs.stdenv;
        symlink = "none";
      }
    ];
  };
in
{
  system.build.tarball = tarball;
}
