{ stdenvForHol4
, graphviz
, python3, perl

, polymlForHol4
, mltonForHol4
, hol4Source

, runCommand
, writeScript
, runtimeShell
}:

let

  w = writeScript "w.sh" ''
    #!${runtimeShell}

    echo "$@" >&2

    exec ${polymlForHol4}/bin/poly "$@"
  '';

  ww = runCommand "ww" {} ''
    mkdir -p $out/bin
    cp ${polymlForHol4}/bin/{polyc,polyimport} $out/bin
    cp ${w} $out/bin/poly
  '';

in

# TODO
# ./bin/build --relocbuild
# ./bin/build -j

stdenvForHol4.mkDerivation {
  name = "hol4";

  src = hol4Source;

  # TODO use nativeBuildInputs
  buildInputs = [
    polymlForHol4
    # ww
    mltonForHol4
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

  # TODO try removing HOLDIR hack now that we don't use decompile.py
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
