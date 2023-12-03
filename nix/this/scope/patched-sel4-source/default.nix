{ stdenv
, python3
, cmake
, scopeConfig
}:

stdenv.mkDerivation {
  name = "sel4-source";

  src = scopeConfig.seL4Source;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python3
  ];

  postPatch = ''
    sed -i 's,#!/usr/bin/env -S cmake -P,#!${cmake}/bin/cmake -P,' configs/*_verified.cmake

    patchShebangs .
  '';

  installPhase = ''
    cp -r . $out
  '';
}
