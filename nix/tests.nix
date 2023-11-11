{ stdenv, lib
, runCommand
, python2Packages, python3Packages
, haskell, haskellPackages
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, isabelle, mlton
, keepBuildTree

, sources
, initial-heaps
, texlive-env
, armv7Pkgs

, verbose ? false
, testTargets ? []
}:

let

  # scaleTimeouts = "4";
  # scaleTimeouts = "1.5";
  # timeouts = "--scale-timeouts ${scaleTimeouts}";

  timeouts = "--no-timeouts";

  parallelism = "-j 1";
  # parallelism = "-j 2";
  # parallelism = "-j $NIX_BUILD_CORES";

  src = runCommand "src" {} ''
    mkdir $out
    cp -r ${sources.l4v} $out/l4v
    cp -r ${sources.seL4} $out/seL4
    cp -r ${isabelle} $out/isabelle
  '';
  # TODO return to ln -s for isabelle

  oldHaskellPackages = haskell.packages.ghc865;

  ghcWithPackages = oldHaskellPackages.ghcWithPackages (p: with p; [
    mtl_2_2_2
  ]);

in
stdenv.mkDerivation {
  name = "tests";

  inherit src;

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2

    mlton

    armv7Pkgs.stdenv.cc

    ghcWithPackages
    haskellPackages.cabal-install

    # python2Packages.sel4-deps
    python3Packages.sel4-deps

    texlive-env

    keepBuildTree # HACK
  ];

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export TOOLPREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export CROSS_COMPILER_PREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export L4V_ARCH=ARM

    cp -r ${initial-heaps} $HOME
    chmod -R +w $HOME
    mkdir -p $HOME/.cabal
    touch $HOME/.cabal/config

    cd l4v
  '';

  buildPhase = ''
    ./run_tests \
      ${timeouts} \
      ${parallelism} \
      ${lib.optionalString verbose "-v"} \
      ${lib.concatStringsSep " " testTargets}
  '';

  installPhase = ''
    echo SUCCESS
  '';

  dontFixup = true;
}

# NOTE:
# RefineOrphanage depends on ./make_spec.sh having run

# NIX_CFLAGS_COMPILE = [ "-Wno-unused-command-line-argument" ];
# NIX_CFLAGS_LINK = [ "-Wno-unused-command-line-argument" "-lm" "-lffi" ];
