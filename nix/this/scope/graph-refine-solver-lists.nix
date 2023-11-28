{ lib
, writeText
, z3
, yices
, cvc4BinaryFromIsabelle
, cvc4Binary
, cvc5Binary
, sonolarBinary
, mathsat5Binary
}:

rec {
  selectedCVC4Binary = cvc4BinaryFromIsabelle.v1_5_3;
  # selectedCVC4Binary = cvc4Binary.v1_5;

  cvc4BinaryExe = "${selectedCVC4Binary}/bin/cvc4";
  cvc5BinaryExe = "${cvc5Binary}/bin/cvc5";
  sonolarBinaryExe = "${sonolarBinary}/bin/sonolar";
  mathsat5Exe = "${mathsat5Binary}/bin/mathsat";
  z3Exe = "${z3}/bin/z3";
  yicesSmt2Exe = "${yices}/bin/yices-smt2";

  # default = original;
  default = new;

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

  experimental = writeText "solverlist" ''
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
    MathSat5: offline: ${mathsat5Exe}
    MathSat5-word8: offline: ${mathsat5Exe}
      config: mem_mode = 8
    Z3: offline: ${z3Exe} -in
    Z3-word8: offline: ${z3Exe} -in
      config: mem_mode = 8
  '';
}
