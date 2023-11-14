{ lib, stdenv
, runCommand
, python3Packages
, haskell, haskellPackages
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, isabelle, mlton
, keepBuildTree

, sources
, isabelleInitialHeaps
, texliveEnv
, l4vConfig
}:

{ buildStandaloneCParser ? false
, export ? false

, testTargets ? null
, verbose ? false
, numJobs ? 1
, timeouts ? false
, timeoutScale ? null
}:

let
  src = runCommand "src" {} ''
    mkdir $out
    ln -s ${isabelle} $out/isabelle
    cp -r ${sources.seL4} $out/seL4
    cp -r ${sources.l4v} $out/l4v
  '';

  ghcWithPackages = haskell.packages.ghc865.ghcWithPackages (p: with p; [
    mtl_2_2_2
  ]);

in
stdenv.mkDerivation {
  name = "l4v";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2

    mlton

    ghcWithPackages
    haskellPackages.cabal-install

    python3Packages.sel4-deps

    texliveEnv

    l4vConfig.targetCC

    # TODO remove
    keepBuildTree # HACK
  ];

  postPatch = ''
    cd l4v
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export ISABELLE_HOME=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME')

    export TOOLPREFIX=${l4vConfig.targetPrefix}
    export CROSS_COMPILER_PREFIX=${l4vConfig.targetPrefix}
    export L4V_ARCH=${l4vConfig.arch}

    cp -r ${isabelleInitialHeaps}/* $HOME/.isabelle --no-preserve=ownership,mode
  '';

  buildPhase = ''
    ${lib.optionalString (testTargets != null) ''
      ./run_tests \
        ${lib.optionalString verbose "-v"} \
        ${lib.optionalString (!timeouts) "--no-timeouts"} \
        ${lib.optionalString (timeoutScale != null) "--scale-timeouts ${toString timeoutScale}"} \
        -j ${toString numJobs} \
        ${lib.concatStringsSep " " testTargets}
    ''}

    ${lib.optionalString buildStandaloneCParser ''
      make -C tools/c-parser/standalone-parser standalone-cparser
    ''}

    ${lib.optionalString export ''
      make -C proof/ SimplExport
    ''}
  '';

  dontInstall = true;
  dontFixup = true;
}

# NOTE:
# RefineOrphanage depends on ./make_spec.sh having run
