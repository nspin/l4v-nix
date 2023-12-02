{ lib, stdenv
, runCommand
, python3Packages
, haskell, haskellPackages
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2

, sources
, mltonForL4v
, isabelleForL4v
, isabelleInitialHeaps
, texliveEnv
, ghcWithPackagesForL4v
, l4vConfig
}:

{ name ? null

, tests ? null
, exclude ? []
, remove ? []
, verbose ? false
, numJobs ? 1
, timeouts ? false
, timeoutScale ? null

, buildStandaloneCParser ? false
, simplExport ? false

, isabelleLink ? buildStandaloneCParser
}:

# NOTE
# The default Isabelle settings seem to be working. Nevertheless, we should consider experimenting
# with some from:
# - l4v/misc/etc/settings
# - seL4-CAmkES-L4v-dockerfiles/res/isabelle_settings

# TODO
# Consider exporting the entire top-level

assert tests == null -> (exclude == [] && remove == []);

let
  src = runCommand "src" {} ''
    mkdir $out
    ln -s ${isabelleForL4v} $out/isabelle
    cp -r ${sources.seL4} $out/seL4
    cp -r ${sources.l4v} $out/l4v
  '';

in
stdenv.mkDerivation {
  name = "l4v${lib.optionalString (name != null) "-${name}"}";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2

    mltonForL4v

    ghcWithPackagesForL4v
    haskellPackages.cabal-install

    python3Packages.sel4-deps

    texliveEnv

    l4vConfig.targetCC
    l4vConfig.targetBintools
  ];

  hardeningDisable = [ "all" ];

  # TODO
  # SKIP_DUPLICATED_PROOFS = 1;
  # What does this do?
  # Is it appropriate?
  # It is set in seL4-CAmkES-L4v-dockerfiles/res/isabelle_settings.

  postPatch = ''
    cd l4v
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export ISABELLE_HOME=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME')

    export L4V_ARCH=${l4vConfig.arch}
    export TOOLPREFIX=${l4vConfig.targetPrefix}

    export SKIP_DUPLICATED_PROOFS=1

    mkdir -p $HOME/.cabal
    touch $HOME/.cabal/config

    cp -r ${isabelleInitialHeaps}/* $HOME/.isabelle --no-preserve=ownership,mode
  '';

  # TODO wrap './run_tests' in 'time' invocation
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
  '' + lib.optionalString isabelleLink ''
    ln -sfT ${isabelleForL4v} isabelle
  '';

  installPhase = ''
    cp -r . $out
  '';

  dontFixup = true;
}
