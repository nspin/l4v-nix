{ stdenv, lib
, runCommand
, python2Packages, python3Packages
, haskell, haskellPackages
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, isabelle, mlton
, keepBuildTree

, sources
, isabelleInitialHeaps
, texliveEnv
, armv7Pkgs
}:

{ buildStandaloneCParser ? false
, export ? false

, testTargets ? null
, verbose ? false
, numJobs ? 1 # "$NIX_BUILD_CORES"
, timeouts ? false
, timeoutScale ? null
}:

# HACK
assert timeoutScale == null;

# TODO

let
  src = runCommand "src" {} ''
    mkdir $out
    cp -r ${sources.l4v} $out/l4v
    cp -r ${sources.seL4} $out/seL4
    ln -s ${isabelle} $out/isabelle
  '';

  oldHaskellPackages = haskell.packages.ghc865;

  ghcWithPackages = oldHaskellPackages.ghcWithPackages (p: with p; [
    mtl_2_2_2
  ]);

in
stdenv.mkDerivation {
  name = "l4v";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2

    mlton

    armv7Pkgs.stdenv.cc

    ghcWithPackages
    haskellPackages.cabal-install

    # TODO remove
    # python2Packages.sel4-deps

    python3Packages.sel4-deps

    texliveEnv

    # TODO remove
    keepBuildTree # HACK
  ];

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export ISABELLE_HOME=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME')

    export TOOLPREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export CROSS_COMPILER_PREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export L4V_ARCH=ARM

    cp -r ${isabelleInitialHeaps}/* $HOME/.isabelle --no-preserve=ownership,mode

    # TODO remove
    mkdir -p $HOME/.cabal
    touch $HOME/.cabal/config

    cd l4v
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
