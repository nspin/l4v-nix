{ lib
, writeText
, writeScript
, writeShellApplication
, runtimeShell
, yices

, cvc4Binary
, cvc5Binary
, sonolarBinary
}:

# TODO
# - tune
# - figure out why are cvc4 >= 1.6 and cvc5 so slow
# - figure out why cvc5 throws ConversationProblem
# - figure out apparent buf in cvc4 1.5 and sonolar (assert self.parallel_solvers)
# - z3 offline

rec {
  cvc4BinaryExe = "${cvc4Binary.v1_5}/bin/cvc4";
  cvc5BinaryExe = "${cvc5Binary}/bin/cvc5";
  sonolarBinaryExe = "${sonolarBinary}/bin/sonolar";
  yicesSmt2Exe = "${yices}/bin/yices-smt2";

  default = original;

  original = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
      config: mem_mode = 8
  '';

  new = writeText "solverlist" ''
    CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    CVC4: offline: ${cvc4BinaryExe} --lang smt
    CVC4-word8: offline: ${cvc4BinaryExe} --lang smt
      config: mem_mode = 8
    SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
      config: mem_mode = 8
    Yices: offline: ${yicesSmt2Exe}
    Yices-word8: offline: ${yicesSmt2Exe}
      config: mem_mode = 8
  '';
}
