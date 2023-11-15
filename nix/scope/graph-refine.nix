{ lib, stdenv
, runCommand
, python2
, python3
, isabelle

, sources
, graphRefineInputs
, l4vConfig
}:

{ targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, commands ? [ [] ]
}:

let
  # TODO
  # - use nixpkgs cvc4
  # - try cvc5
  solverList = runCommand "solverlist" {
    nativeBuildInputs = [
      isabelle
    ];
  } ''
    export HOME=$(mktemp -d --suffix=-home)

    cvc4=$(isabelle env bash -c 'echo $CVC4_SOLVER')
    cat > $out << EOF
    CVC4: online: $cvc4 --incremental --lang smt --tlimit=5000
    CVC4: offline: $cvc4 --lang smt
    EOF
  '';

in
stdenv.mkDerivation {

  # TODO extend with arg
  name = "graph-refine";

  nativeBuildInputs = [
    isabelle
    python2
    python3
  ];

  buildCommand = ''
    ln -s ${solverList} .solverlist
    cp -r --no-preserve=owner,mode ${targetDir} target
    cd target

    ${lib.flip lib.concatMapStrings commands (args: ''
      python ${sources.graphRefineNoSeL4}/graph-refine.py . ${lib.concatStringsSep " " args}
    '')}

    cp -r . $out
  '';

  passthru = {
    inherit solverList;
  };
}
