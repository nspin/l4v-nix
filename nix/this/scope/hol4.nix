{ stdenvForHol4
, makeFontsConf
, python3, perl
, graphviz

, polymlForHol4
, mltonForHol4
, hol4Source
}:

# TODO
# Address:
# Fontconfig error: No writable cache directories

# TODO
# ./bin/build -j $NIX_BUILD_CORES
# ./bin/build --relocbuild

let
in

stdenvForHol4.mkDerivation {
  name = "hol4";

  src = hol4Source;

  phases = [ "unpackPhase" "patchPhase" "buildPhase" ];

  nativeBuildInputs = [
    polymlForHol4 mltonForHol4
    python3 perl
    graphviz
  ];

  # FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    # avoid noisy warning from fontconfig
    export HOME=$(mktemp -d --suffix=-home)

    holdir=$out

    cp -r . $holdir
    cd $holdir

    poly < tools/smart-configure.sml
    bin/build
    (cd examples/machine-code/graph && $holdir/bin/Holmake)
  '';
}
