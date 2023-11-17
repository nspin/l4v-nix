{ lib, stdenv
, runCommand, writeText
, python2

, sources
, isabelleForL4v
, graphRefineInputs
, cvc4Binary
, sonolarBinary
, l4vConfig
}:

{ name ? null
, targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, commands ? [ [] ]
}:

let
  # TODO
  # - tune
  # - figure out why are cvc4 >= 1.6 and cvc5 so slow?
  # - figure out why cvc5 throws ConversationProblem

  solverList = solverLists.likeDockerImage;

  cvc4BinaryExe = "${cvc4Binary.v1_5}/bin/cvc5";
  sonolarExe = "${sonolarBinary}/bin/sonolar";

  solverLists = {
    # see git history for other configurations and related measurements
    likeDockerImage = writeText "solverlist" ''
      CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
      SONOLAR: offline: ${sonolarExe} --input-format=smtlib2
      CVC4: offline: ${cvc4BinaryExe} --lang smt
      SONOLAR-word8: offline: ${sonolarExe} --input-format=smtlib2
        config: mem_mode = 8
    '';
  };

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
      time python ${sources.graphRefineNoSeL4}/graph-refine.py . ${lib.concatStringsSep " " args}
    '')}

    cp -r . $out
  '';

  passthru = {
    inherit solverList;
  };
}
