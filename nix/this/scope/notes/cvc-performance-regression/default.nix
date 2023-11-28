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

  mk = name: exe: includeDemo:
    let
      solverList = writeText "solverlist" ''
        CVC: online: ${exe} --incremental --lang smt --tlimit=5000
        SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
        CVC: offline: ${exe} --lang smt
        SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
          config: mem_mode = 8
      '';

      justStackBounds = graphRefineWith {
        name = "cvc-regression-case-${name}-stack-bounds";
        inherit solverList;
      };

      demo = graphRefineWith {
        name = "cvc-regression-case-${name}-demo";
        inherit solverList;
        targetDir = justStackBounds;
        args = [
          "trace-to:report.txt"
          "deps:Kernel_C.cancelAllIPC"
        ];
      };
    in {
      inherit justStackBounds;
    } // lib.optionalAttrs includeDemo {
      inherit demo;
    };

in rec {
  cases = {
    cvc4v1_5 = mk "cvc4v1_5" "${cvc4Binary.v1_5}/bin/cvc4" true;
    cvc4v1_6 = mk "cvc4v1_6" "${cvc4Binary.v1_6}/bin/cvc4" true;
    cvc4v1_8 = mk "cvc4v1_8" "${cvc4Binary.v1_8}/bin/cvc4" true;
    cvc5v1_0_8 = mk "cvc5v1_0_8" "${cvc5Binary}/bin/cvc5" true; # demo takes ~30min (!)
  };

  evidence = linkFarm "evidence" (lib.concatLists (lib.flip lib.mapAttrsToList cases (caseName: case:
    lib.flip lib.mapAttrsToList case (runName: run:
      { name = "${caseName}-${runName}"; path = run; }
    )
  )));
}
