{ stdenv, lib
, runCommand
, python2Packages, python3Packages
, haskell, haskellPackages
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, isabelle, mlton

, sources
, initial-heaps
, texlive-env
, armv7Pkgs

, verbose ? false
, testTargets ? []
}:

let

  # scaleTimeouts = "4";
  scaleTimeouts = "1.5";

  # j = "1";
  j = "2";

  # j = "$NIX_BUILD_CORES";

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
  ];

  configurePhase = ''
    export L4V_ARCH=ARM
    export TOOLPREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export CROSS_COMPILER_PREFIX=${armv7Pkgs.stdenv.cc.targetPrefix}
    export HOME=$NIX_BUILD_TOP/home

    cp -r ${initial-heaps} $HOME
    chmod -R +w $HOME
    mkdir -p $HOME/.cabal
    touch $HOME/.cabal/config

    cd l4v
  '';

  buildPhase = ''
    ./run_tests \
      --scale-timeouts ${scaleTimeouts} \
      -j ${j} \
      ${lib.optionalString verbose "-v"} \
      ${lib.concatStringsSep " " testTargets}
  '';
    # --no-timeouts \

  installPhase = ''
    echo SUCCESS
    touch $out
    false
  '';
}

# NOTE:
# RefineOrphanage depends on ./make_spec.sh having run

# NIX_CFLAGS_COMPILE = [ "-Wno-unused-command-line-argument" ];
# NIX_CFLAGS_LINK = [ "-Wno-unused-command-line-argument" "-lm" "-lffi" ];
