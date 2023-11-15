{ lib, stdenv
, runCommand, writeText
, python2
, cvc5
, cvc4

, sources
, isabelle
, sonolar
, graphRefineInputs
, l4vConfig
}:

{ name ? null
, targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, commands ? [ [] ]
}:

let
  solverList = defaultSolverList;

  cvc4Exe = "${cvc4}/bin/cvc4";
  cvc5Exe = "${cvc5}/bin/cvc5";
  sonolarExe = "${sonolar}/bin/sonolar";

  # TODO
  # - get working
  # - tune
  nextSolverList = writeText "solverlist" ''
    CVC4: online: ${cvc4Exe} --incremental --lang smt --tlimit=5000
    CVC4: offline: ${cvc4Exe} --lang smt
  '';
    # CVC5: online: ${cvc5Exe} --incremental --lang smt --tlimit=5000
    # CVC5: offline: ${cvc5Exe} --lang smt
    # SONOLAR: offline: ${sonolarExe} --input-format=smtlib2

  defaultSolverList = runCommand "solverlist" {
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
  name = "graph-refine${lib.optionalString (name != null) "-${name}"}";

  nativeBuildInputs = [
    python2
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
