{
  stdenv,
  python3
}:

stdenv.mkDerivation {
  name = "status_command";
  propagatedBuildInputs = [
    (python3.withPackages ( p: [ p.dbus-python ]))
  ];
  dontUnpack = true;
  installPhase = "install -D -m755 ${./utils/status_command.py} $out/bin/status_command";
}
