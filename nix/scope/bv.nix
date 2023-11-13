{ stdenv
, runCommand
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, polyml, mlton
, python2Packages
, python3Packages
, isabelle
, keepBuildTree

, sources
, texlive-env
, initial-heaps
, hol4
, armv7Pkgs
, export
}:

let
  src = runCommand "src" {} ''
    mkdir $out
    cp -r ${sources.graph-refine} $out/graph-refine
    cp -r ${sources.seL4} $out/seL4
    cp -r ${export}/.build/src/l4v $out/l4v
    ln -s ${isabelle} $out/isabelle
  '';
    # cp -r ${sources.l4v} $out/l4v

in
stdenv.mkDerivation {
  name = "bv";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2
    polyml mlton
    python2Packages.python
    python3Packages.sel4-deps
    armv7Pkgs.stdenv.cc

    texlive-env

    # keepBuildTree # HACK
  ];

  postPatch = ''
    patchShebangs .
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export ISABELLE_HOME=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME')

    export TOOLPREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export CROSS_COMPILER_PREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}

    export HOL4_ROOT=${hol4}/src/hol4

    export L4V_ARCH=ARM

    export OBJDUMP=''${TOOLPREFIX}objdump

    if [ -n "$IN_NIX_SHELL" ]; then
      export -p >shell-env.sh
    fi

    cp -r ${initial-heaps}/* $HOME/.isabelle --no-preserve=ownership,mode

    cd graph-refine/seL4-example
  '';

  buildPhase = ''
    make StackBounds
  '';

  dontInstall = true;
  dontFixup = true;
}
