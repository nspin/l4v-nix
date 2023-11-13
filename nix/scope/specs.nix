{ lib, stdenv
, buildPackages
, python3Packages
, rsync, git, hostname
, perl
, isabelle

, sources
, initial-heaps
, texlive-env
}:

let
  versionFile = builtins.toFile "VERSION" "unknown";

in
stdenv.mkDerivation {
  name = "specs";

  src = sources.l4v;

  depsBuildBuild = [
    buildPackages.stdenv.cc
  ];

  nativeBuildInputs = [
    rsync git hostname
    perl
    python3Packages.sel4-deps
    texlive-env
  ];

  postPatch = ''
    patchShebangs .

    substituteInPlace spec/Makefile \
      --replace SEL4_VERSION=../../seL4/VERSION SEL4_VERSION=${versionFile}
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    cp -r ${initial-heaps}/* $HOME/.isabelle --no-preserve=ownership,mode

    ln -sf ${isabelle} isabelle
  '';

  buildPhase = ''
    mkdir $out
    cd spec

    do_arch() {
      L4V_ARCH=$1 make ASpec
      cp -v $HOME/.isabelle/Isabelle2020/browser_info/Specifications/ASpec/document.pdf $out/$1.pdf
    }

    do_arch ARM
    do_arch ARM_HYP
    do_arch RISCV64
    do_arch X64
  '';

  dontInstall = true;
}
