{ stdenv
, polyml
, mlton
, graphviz
, python3
, perl
, keepBuildTree

, sources
}:

stdenv.mkDerivation {
  name = "hol4";

  src = sources.hol4;

  buildInputs = [
    polyml mlton graphviz
    python3 perl
    keepBuildTree
  ];

  postPatch = ''
    patchShebangs .

    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace '"/bin/mv"' '"mv"' \
      --replace '"/bin/cp"' '"cp"'
  '';

  configurePhase = ''
    # $HOLDIR hack
    old=$(pwd)
    cd $NIX_BUILD_TOP
    new=src/HOL4
    mkdir -p $(dirname $new)
    mv $old $new
    cd $new

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
