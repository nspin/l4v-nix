{ stdenv
, runCommand
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, polyml, mlton
, python2Packages
, python3Packages
, isabelle
, keepBuildTree

, sources
, armv7Pkgs
, graphRefineInputs
}:

stdenv.mkDerivation {
  name = "bv";

  src = sources.graph-refine;

  nativeBuildInputs = [
    python2Packages.python
    python3Packages.python

    # keepBuildTree # HACK
  ];

  postPatch = ''
    patchShebangs .
  '';

  configurePhase = ''
    export L4V_ARCH=ARM

    cd graph-refine/seL4-example

    cp -r ${graphRefineInputs} target --no-preserve=owner,mode
  '';

  buildPhase = ''
    make StackBounds coverage target/ARM-O1/demo-report.txt
  '';

  installPhase = ''
    cp -r target $out
  '';

  dontFixup = true;
}
