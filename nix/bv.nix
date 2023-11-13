{ stdenv
, python2Packages

, sources
}:

stdenv.mkDerivation {
  name = "bv";

  src = sources.graph-refine;

  buildInputs = [
    python2Packages.python
  ];

  postPatch = ''
    patchShebangs .
  '';

  configurePhase = ''
    false
  '';

  buildPhase = ''
    false
  '';

  installPhase = ''
    false
  '';

  dontFixup = true;
}
