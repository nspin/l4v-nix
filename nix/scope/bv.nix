{ stdenv
, runCommand
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2
, polyml, mlton
, python2Packages
, python3Packages
, isabelle

, sources
, graphRefineInputs
}:

stdenv.mkDerivation {
  name = "bv";

  src = graphRefineInputs;

  sourceRoot = "${graphRefineInputs.name}/ARM-O1";

  phases = [ "unpackPhase" "configurePhase" "buildPhase" "installPhase" ];

  nativeBuildInputs = [
    isabelle
    python2Packages.python
    python3Packages.python
  ];

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export L4V_ARCH=ARM

    f=.solverlist
    cvc4=$(isabelle env bash -c 'echo $CVC4_SOLVER')
    echo "CVC4: online: $cvc4 --incremental --lang smt --tlimit=5000" >> $f
    echo "CVC4: offline: $cvc4 --lang smt" >> $f
  '';

  buildPhase = ''
    script="python ${sources.graph-refine}/graph-refine.py ."

    $script
	  $script trace-to:$@.partial coverage
    $script trace-to:demo-report.txt deps:Kernel_C.cancelAllIPC
  '';

  installPhase = ''
    cp -r . $out
  '';
}
