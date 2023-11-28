{ lib
, writeText
, linkFarm

, graphRefine
, graphRefineSolverLists
, graphRefineWith
, cvc4Binary
, cvc5Binary
}:

let
  inherit (graphRefineSolverLists) sonolarBinaryExe;

  mk = name: exe: graphRefineWith {
    name = "cvc-regression-case-${name}";
    solverList = writeText "solverlist" ''
      CVC: online: ${exe} --incremental --lang smt --tlimit=5000
      SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
      CVC: offline: ${exe} --lang smt
      SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
        config: mem_mode = 8
    '';
    targetDir = graphRefine.justStackBounds;
    args = [
      "trace-to:report.txt"
      "deps:Kernel_C.cancelAllIPC"
    ];
  };

in rec {
  cases = {
    cvc4v1_5 = mk "v1_5" "${cvc4Binary.v1_5}/bin/cvc4";
    cvc4v1_6 = mk "v1_6" "${cvc4Binary.v1_6}/bin/cvc4";
    cvc5 = mk "v1_6" "${cvc5Binary}/bin/cvc5";
  };

  evidence = linkFarm "evidence" cases;
}
