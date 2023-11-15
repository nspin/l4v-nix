{ stdenv
, python3
, cmake
, rawSources
}:

stdenv.mkDerivation {
  name = "sel4-source";

  src = rawSources.seL4;

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
