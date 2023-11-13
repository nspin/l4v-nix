{ stdenv
, python2Packages

, sources
, hol4
, armv7Pkgs
, tests
}:

let
  src = runCommand "src" {} ''
    mkdir $out
    ln -s ${tests}/.build/src $out/l4v
    cp -r ${sources.graph-refine} $out/graph-refine
  '';

in
stdenv.mkDerivation {
  name = "bv";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2
    polyml mlton
    python2Packages.python
    armv7Pkgs.stdenv.cc
  ];

  postPatch = ''
    patchShebangs .
  '';

  configurePhase = ''
    cd seL4-example

    export TOOLPREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export CROSS_COMPILER_PREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}

    export HOL4_ROOT=${hol4}/src/hol4

    export L4V_ARCH=ARM
  '';

  buildPhase = ''
    false
  '';

  installPhase = ''
    false
  '';

  dontFixup = true;
}
