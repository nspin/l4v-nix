{ stdenvForHol4
, graphviz
, python3, perl

, polymlForHol4
, mltonForHol4
, hol4Source
}:

stdenvForHol4.mkDerivation {
  name = "hol4";

  src = hol4Source;

  buildInputs = [
    polymlForHol4 mltonForHol4
    graphviz
    python3 perl
  ];

  # TODO patch "/bin/unquote" too
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
