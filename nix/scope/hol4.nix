{ stdenv
, graphviz
, python3, perl

, sources
, polyml, mlton
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
    # $HOLDIR hack
    holdir=$NIX_BUILD_TOP/src/HOL4
    mkdir -p $(dirname $holdir)
    old=$(pwd)
    cd /
    mv $old $holdir
    cd $holdir

    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build
    (cd examples/machine-code/graph && $holdir/bin/Holmake)
  '';

  installPhase = ''
    cp -r . $out
  '';
}
