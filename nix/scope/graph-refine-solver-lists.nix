{ lib
, writeText
, writeShellApplication
, yices

, cvc4Binary
, sonolarBinary
}:

# TODO
# - tune
# - figure out why are cvc4 >= 1.6 and cvc5 so slow
# - figure out why cvc5 throws ConversationProblem
# - figure out why sonolar with mem_mode = 8 doesn't work
# - z3 offline

let
  cvc4BinaryExe = "${cvc4Binary.v1_5}/bin/cvc4";
  sonolarBinaryExe = "${sonolarBinary}/bin/sonolar";
  yicesSmt2Exe = "${yices}/bin/yices-smt2";

  sonolarWrapper = writeShellApplication {
    name = "x";
    text = ''
      cat | tee -a in.txt | ${sonolarBinaryExe} --input-format=smtlib2
    '';
  };

  sonolarWrapperExe = "${sonolarWrapper}/bin/x";

in {
  default = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    Yices: offline: ${yicesSmt2Exe}
    CVC4-word8: offline: ${cvc4BinaryExe} --lang smt
      config: mem_mode = 8
    Yices-word8: offline: ${yicesSmt2Exe}
      config: mem_mode = 8
  '';
    # TODO
    # SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
    #   config: mem_mode = 8

  wip1 = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
      config: mem_mode = 8
  '';
    # SONOLAR: offline: ${sonolarWrapperExe}
    # SONOLAR: offline: ${sonolarWrapperExe} --input-format=smtlib2
}
