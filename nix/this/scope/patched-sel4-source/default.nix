{ stdenvNoCC
, python3
, cmake
, scopeConfig
}:

stdenvNoCC.mkDerivation {
  name = "sel4-source";

  src = scopeConfig.seL4Source;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python3
  ];

  postPatch = ''
    patchShebangs .
  '';

  installPhase = ''
    cp -r . $out
  '';
}
