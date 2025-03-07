{
  stdenv,
  python3
}:

stdenv.mkDerivation {
  name = "ddns";
  propagatedBuildInputs = [
    (python3.withPackages ( p: [ p.requests ]))
  ];
  dontUnpack = true;
  installPhase = "install -D -m755 ${./utils/ddns_update.py} $out/bin/ddns_update";
}
