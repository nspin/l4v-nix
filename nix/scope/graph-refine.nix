{ lib, stdenv
, python2Packages
, python3Packages
, isabelle

, sources
, graphRefineInputs
, l4vConfig
}:

{ target ? "all"
}:

assert !allFunctions -> (justFunction != null);

stdenv.mkDerivation {
  name = "graph-refine";

  src = graphRefineInputs;

  nativeBuildInputs = [
    isabelle
    python2Packages.python
    python3Packages.python
  ];

  prePatch = ''
    cd ${l4vConfig.arch}${l4vConfig.optLevel}
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
    $script trace-to:report.txt ${target}
  '';

  installPhase = ''
    cp -r . $out
  '';

  dontFixup = true;
}
