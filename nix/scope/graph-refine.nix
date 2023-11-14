{ lib, stdenv
, python2Packages
, python3Packages
, isabelle

, sources
, graphRefineInputs
, l4vConfig

, allFunctions ? false
}:

stdenv.mkDerivation {
  name = "graph-refine";

  src = graphRefineInputs;

  nativeBuildInputs = [
    isabelle
    python2Packages.python
    python3Packages.python
  ];

  prePatch = ''
    cd ${l4vConfig.arch}-${l4vConfig.optLevel}
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export L4V_ARCH=${l4vConfig.arch}

    solverlist=.solverlist
    cvc4=$(isabelle env bash -c 'echo $CVC4_SOLVER')
    echo "CVC4: online: $cvc4 --incremental --lang smt --tlimit=5000" >> $solverlist
    echo "CVC4: offline: $cvc4 --lang smt" >> $solverlist
  '';

  buildPhase = ''
    script="python ${sources.graph-refine}/graph-refine.py ."

    $script
	  $script trace-to:coverage.txt.partial coverage
    $script trace-to:demo-report.txt deps:Kernel_C.cancelAllIPC
  '' + lib.optionalString allFunctions ''
    $script trace-to:report.txt all
  '';

  installPhase = ''
    cp -r . $out
  '';

  dontFixup = true;
}
