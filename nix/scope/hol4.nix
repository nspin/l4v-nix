{ stdenv
, polyml, mlton
, graphviz
, python3, perl

, sources
}:

stdenv.mkDerivation {
  name = "hol4";

  src = sources.hol4;

  buildInputs = [
    polyml mlton
    graphviz
    python3 perl
  ];

  postPatch = ''
    patchShebangs .

    substituteInPlace \
      tools/Holmake/Holmake_types.sml \
        --replace '"/bin/mv"' '"mv"' \
        --replace '"/bin/cp"' '"cp"'
  '';

  configurePhase = ''
    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build
    holdir=$(pwd)
    (cd examples/machine-code/graph && $holdir/bin/Holmake)
  '';

  installPhase = ''
    cp -r . $out
  '';
}
