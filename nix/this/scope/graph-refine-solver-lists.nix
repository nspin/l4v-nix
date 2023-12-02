{ lib
, writeText
, z3
, yices

, sources

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

  default = matt;

  mattFn = import (sources.graphRefine + "/nix/solvers.nix");

  mattDir = (mattFn { use_sonolar = false; }).solverlist;

  matt = "${mattDir}/.solverlist";

}
