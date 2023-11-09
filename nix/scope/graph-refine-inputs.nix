{ stdenv
, runCommand
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, polyml, mlton
, python2Packages
, python3Packages
, isabelle
, keepBuildTree

, strace

, sources
, texlive-env
, initial-heaps
, hol4
, armv7Pkgs
, bvInput
}:

let
  src = runCommand "src" {} ''
    mkdir $out
    ln -s ${isabelle} $out/isabelle
    cp -r ${sources.seL4} $out/seL4
    cp -r ${sources.graph-refine} $out/graph-refine
    cp -r ${bvInput}/.build/src/l4v $out/l4v
    cp -r ${hol4} $out/HOL4
  '';

in
stdenv.mkDerivation {

  # TODO rename
  name = "bv";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2
    polyml mlton
    python2Packages.python
    python3Packages.sel4-deps
    armv7Pkgs.stdenv.cc

    strace

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
    export L4V_ARCH=ARM

    export OBJDUMP=''${TOOLPREFIX}objdump

    cd graph-refine/seL4-example
  '';

  buildPhase = ''
    make diff graph-refine-inputs
  '';

  installPhase = ''
    cp -r target $out
  '';

  dontFixup = true;
}

# if [ -n "$IN_NIX_SHELL" ]; then
#   export -p >shell-env.sh
# fi

# # HACK
# substituteInPlace \
#   HOL4/examples/machine-code/graph/decompile.py \
#     --replace \
#       'sys.stdout.write(str)' \
#       's = str; sys.stdout.write(s); sys.stdout.write("\n"); sys.stdout.flush()' \
#     --replace \
#       ' stdout=out, stderr=out,' \
#       '''
