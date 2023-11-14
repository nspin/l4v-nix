{ stdenv
, python2Packages
, python3Packages
, isabelle

, sources
, graphRefineInputs
}:

stdenv.mkDerivation rec {
  name = "bv";

  src = graphRefineInputs;

  nativeBuildInputs = [
    isabelle
    python2Packages.python
    python3Packages.python
  ];

  prePatch = ''
    cd ARM-O1
  '';

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
	  $script trace-to:coverage.txt.partial coverage
    $script trace-to:demo-report.txt deps:Kernel_C.cancelAllIPC
    # $script trace-to:report.txt all
  '';

  installPhase = ''
    cp -r . $out
  '';

  dontFixup = true;
}
