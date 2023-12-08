{ stdenvForHol4
, makeFontsConf
, python3, perl
, fontconfig
, graphviz

, polymlForHol4
, mltonForHol4
, hol4Source
}:

# TODO
# ./bin/build -j $NIX_BUILD_CORES
# ./bin/build --relocbuild

let
  fontconfigFile = makeFontsConf { fontDirectories = [ ]; };
in

stdenvForHol4.mkDerivation {
  name = "hol4";

  src = hol4Source;

  phases = [ "unpackPhase" "patchPhase" "buildPhase" ];

  nativeBuildInputs = [
    polymlForHol4 mltonForHol4
    python3 perl
    fontconfig
    graphviz
  ];

  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    export FONTCONFIG_FILE=$(pwd)/fonts.conf
    cp --no-preserve=mode,ownership ${fontconfigFile} $FONTCONFIG_FILE

    holdir=$out

    cp -r . $holdir
    cd $holdir

    poly < tools/smart-configure.sml
    bin/build
    (cd examples/machine-code/graph && $holdir/bin/Holmake)
  '';
}
