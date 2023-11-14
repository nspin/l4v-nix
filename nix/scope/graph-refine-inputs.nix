{ stdenv
, runCommand
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, polyml, mlton
, python2Packages
, python3Packages
, isabelle

, sources
, hol4
, binaryVerificationInputs
, l4vConfig
}:

let
  src = runCommand "src" {} ''
    mkdir $out
    ln -s ${isabelle} $out/isabelle
    cp -r ${sources.seL4} $out/seL4
    cp -r ${sources.graphRefineJustSeL4} $out/graph-refine
    cp -r ${hol4} $out/HOL4
    cp -r ${binaryVerificationInputs} $out/l4v
  '';

in
stdenv.mkDerivation {
  name = "graph-refine-inputs";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2
    polyml mlton
    python2Packages.python
    python3Packages.sel4-deps
    l4vConfig.targetCC
  ];

  postPatch = ''
    patchShebangs .
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export ISABELLE_HOME=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME')

    export TOOLPREFIX=${l4vConfig.targetPrefix}
    export CROSS_COMPILER_PREFIX=${l4vConfig.targetPrefix}
    export L4V_ARCH=${l4vConfig.arch}
    export CONFIG_OPTIMISATION_LEVEL=${l4vConfig.optLevel}

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
