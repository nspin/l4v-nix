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
, ghcWithPackagesForL4v
, l4vConfig
, oldNixpkgs
}:

{ tests ? null
, exclude ? []
, remove ? []
, verbose ? false
, numJobs ? 1
, timeouts ? false
, timeoutScale ? null

, buildStandaloneCParser ? false
, simplExport ? false
}:

assert tests == null -> (exclude == [] && remove == []);

let
  src = runCommand "src" {} ''
    mkdir $out
    ln -s ${isabelle} $out/isabelle
    cp -r ${sources.seL4} $out/seL4
    cp -r ${sources.l4v} $out/l4v
  '';

  ghcWithPackages = ghcWithPackagesForL4v;

  # ghcWithPackages = oldNixpkgs.haskell.packages.ghc865.ghcWithPackages (p: with p; [
  #   mtl_2_2_2
  # ]);

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

    mkdir -p $HOME/.cabal
    touch $HOME/.cabal/config

    cp -r ${isabelleInitialHeaps}/* $HOME/.isabelle --no-preserve=ownership,mode
  '';

  buildPhase = ''
    ${lib.optionalString (tests != null) ''
      ./run_tests \
        ${lib.optionalString verbose "-v"} \
        ${lib.optionalString (!timeouts) "--no-timeouts"} \
        ${lib.optionalString (timeoutScale != null) "--scale-timeouts ${toString timeoutScale}"} \
        -j ${toString numJobs} \
        ${lib.concatMapStringsSep " " (test: "-x ${test}") exclude} \
        ${lib.concatMapStringsSep " " (test: "-r ${test}") remove} \
        ${lib.concatStringsSep " " tests}

      ${lib.optionalString (lib.elem "ASpec" tests) ''
        cp -v \
          $HOME/.isabelle/Isabelle2020/browser_info/Specifications/ASpec/document.pdf \
          spec/abstract
      ''}
    ''}

    ${lib.optionalString buildStandaloneCParser ''
      make -C tools/c-parser/standalone-parser standalone-cparser
    ''}

    ${lib.optionalString simplExport ''
      make -C proof/ SimplExport
    ''}
  '';

  installPhase = ''
    cp -r . $out
  '';

  dontFixup = true;
}

# NOTE:
# RefineOrphanage depends on ./make_spec.sh having run
