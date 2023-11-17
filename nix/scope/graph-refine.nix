{ lib, stdenv
, runCommand, writeText
, python2
, cvc5
, cvc4
, cvc5Binary
, cvc4Binary

, sources
, isabelle
, sonolarBinary
, graphRefineInputs
, l4vConfig
}:

{ name ? null
, targetDir ? "${graphRefineInputs}/${l4vConfig.arch}${l4vConfig.optLevel}"
, commands ? [ [] ]
}:

let
  # TODO tune
  solverList = solverLists.likeDockerImageExceptCvc4_1_5_4;

  cvc4Exe = "${cvc4}/bin/cvc4";
  cvc5Exe = "${cvc5}/bin/cvc5";
  cvc4BinaryExe = "${cvc4Binary}/bin/cvc4";
  cvc5BinaryExe = "${cvc5Binary}/bin/cvc5";
  sonolarExe = "${sonolarBinary}/bin/sonolar";

  # cvc5 throws ConversationProblem

  solverLists = {

    # Timing results are for:
    # ```
    # x = graphRefineWith {
    #   name = "x";
    #   commands = [
    #     [ "trace-to:coverage.txt" "coverage" ]
    #     [ "trace-to:report.txt" "deps:Kernel_C.cancelAllIPC" ]
    #   ];
    # };
    # ```
    # First result is just "deps:Kernel_C.cancelAllIPC", second is total nix-instantiate --realize.

    # real    23m36.553s
    # user    29m56.229s
    # sys     0m20.962s
    #
    # real    32m0.808s
    # user    0m0.019s
    # sys     0m0.022s
    likeDockerImageWithNixpkgsCVC5 = writeText "solverlist" ''
      CVC5: online: ${cvc5Exe} --incremental --lang smt --tlimit=5000
      SONOLAR: offline: ${sonolarExe} --input-format=smtlib2
      CVC5: offline: ${cvc5Exe} --lang smt
      SONOLAR-word8: offline: ${sonolarExe} --input-format=smtlib2
        config: mem_mode = 8
    '';

    likeDockerImageWithNixpkgsCVC4 = writeText "solverlist" ''
      CVC4: online: ${cvc4Exe} --incremental --lang smt --tlimit=5000
      SONOLAR: offline: ${sonolarExe} --input-format=smtlib2
      CVC4: offline: ${cvc4Exe} --lang smt
      SONOLAR-word8: offline: ${sonolarExe} --input-format=smtlib2
        config: mem_mode = 8
    '';

    # real    97m16.178s
    # user    154m16.031s
    # sys     17m30.143s
    #
    # real    110m14.495s
    # user    0m0.018s
    # sys     0m0.019s
    justCVC5 = writeText "solverlist" ''
      CVC5: online: ${cvc5Exe} --incremental --lang smt --tlimit=5000
      CVC5: offline: ${cvc5Exe} --lang smt
    '';

    # real    102m22.328s
    # user    202m17.949s
    # sys     0m15.074s
    #
    # real    110m30.561s
    # user    0m0.018s
    # sys     0m0.021s
    justCVC4 = writeText "solverlist" ''
      CVC4: online: ${cvc4Exe} --incremental --lang smt --tlimit=5000
      CVC4: offline: ${cvc4Exe} --lang smt
    '';

    justCVC5Binary = writeText "solverlist" ''
      CVC5: online: ${cvc5BinaryExe} --incremental --lang smt --tlimit=5000
      CVC5: offline: ${cvc5BinaryExe} --lang smt
    '';

    # with cvc4-1.5:
    #
    # real    16m14.659s
    # user    29m49.184s
    # sys     0m20.498s
    #
    # real    24m9.273s
    # user    0m0.020s
    # sys     0m0.015s
    #
    # with cvc4-1.6:
    #
    # real    21m46.473s
    # user    40m46.503s
    # sys     0m20.234s
    #
    # real    29m30.070s
    # user    0m0.021s
    # sys     0m0.014s
    justCVC4Binary = writeText "solverlist" ''
      CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
      CVC4: offline: ${cvc4BinaryExe} --lang smt
    '';

    # real    16m14.182s
    # user    29m48.056s
    # sys     0m20.420s
    #
    # ?
    likeDefault = runCommand "solverlist" {
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

    # real    2m45.355s
    # user    4m56.937s
    # sys     0m23.768s
    #
    # real    10m29.731s
    # user    0m0.020s
    # sys     0m0.015s
    likeDockerImageUsingIsabelle = runCommand "solverlist" {
      nativeBuildInputs = [
        isabelle
      ];
    } ''
      export HOME=$(mktemp -d --suffix=-home)

      cvc4=$(isabelle env bash -c 'echo $CVC4_SOLVER')
      cat > $out << EOF
      CVC4: online: $cvc4 --incremental --lang smt --tlimit=5000
      SONOLAR: offline: ${sonolarExe} --input-format=smtlib2
      CVC4: offline: $cvc4 --lang smt
      SONOLAR-word8: offline: ${sonolarExe} --input-format=smtlib2
        config: mem_mode = 8
      EOF
    '';

    # with cvc4-1.5:
    #
    # real    2m40.552s
    # user    4m52.913s
    # sys     0m22.710s
    #
    # ?
    likeDockerImageExceptCvc4_1_5_4 = writeText "solverlist" ''
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
