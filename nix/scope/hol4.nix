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

  # $HOLDIR hack
  postUnpack = ''
    old=$(pwd)
    cd $NIX_BUILD_TOP
    new=src/HOL4
    mkdir -p $(dirname $new)
    mv $old $new
    cd $new
  '';

  postPatch = ''
    patchShebangs .

    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace '"/bin/mv"' '"mv"' \
      --replace '"/bin/cp"' '"cp"'
  '';

  configurePhase = ''
    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build
  '';

  # installPhase = ''
  #   # mkdir -p $out/bin
  #   # ln -st $out/bin bin/hol* bin/Holmake
  # '';

  dontInstall = true;
}
