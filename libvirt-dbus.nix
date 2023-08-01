{ lib
, stdenv
, fetchurl
, meson
, ninja
, pkg-config
, libvirt
, libvirt-glib
, glib
, docutils
}:

stdenv.mkDerivation rec {
  pname = "libvirt-dbus";
  version = "1.4.1";

  src = fetchurl {
    url = "https://gitlab.com/libvirt/${pname}/-/archive/v${version}/libvirt-dbus-v1.4.1.tar.gz";
    sha256 = "352jK+dQ3bmorXD5T2tcd+cR4A3EOsuH2KuQrBqBZn4=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    docutils
 ];

  buildInputs = [
    libvirt
    libvirt-glib
    glib
 ];
}
