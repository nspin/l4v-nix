{ lib
, writeText
, yices
, cvc4Binary
, cvc5Binary
, sonolarBinary
}:

rec {
  selectedCvc4Binary = cvc4Binary.v1_5;

  cvc4BinaryExe = "${selectedCvc4Binary}/bin/cvc4";
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
