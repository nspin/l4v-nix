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

  mk = { name, exe, withSonolar ? true, includeDemo ? true }:
    let
      caseName = "${name}-${if withSonolar then "with" else "without"}-sonolar";

      solverList = writeText "solverlist" (''
        CVC: online: ${exe} --incremental --lang smt --tlimit=5000
      '' + lib.optionalString withSonolar ''
        SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
      '' + ''
        CVC: offline: ${exe} --lang smt
      '' + lib.optionalString withSonolar ''
        SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
          config: mem_mode = 8
      '');

      justStackBounds = graphRefineWith {
        name = "cvc-versions-case-${caseName}-stack-bounds";
        inherit solverList;
      };

      demo = graphRefineWith {
        name = "cvc-versions-case-${caseName}-demo";
        inherit solverList;
        targetDir = justStackBounds;
        args = [
          "trace-to:report.txt"
          "deps:Kernel_C.cancelAllIPC"
        ];
      };

      links = linkFarm "${caseName}-links" ({
        stack-bounds = justStackBounds;
      } // lib.optionalAttrs includeDemo {
        inherit demo;
      });
    in {
      inherit caseName justStackBounds demo links;
    };

in rec {
  cases = lib.listToAttrs (map (case: lib.nameValuePair case.caseName case) (lib.flatten (lib.forEach [ true false ] (withSonolar: [
    (mk {
      name = "cvc4v1_5";
      exe = "${cvc4Binary.v1_5}/bin/cvc4";
      inherit withSonolar;
    })
    (mk {
      name = "cvc4v1_6";
      exe = "${cvc4Binary.v1_6}/bin/cvc4";
      inherit withSonolar;
    })
    (mk {
      name = "cvc4v1_8";
      exe = "${cvc4Binary.v1_8}/bin/cvc4";
      inherit withSonolar;
    })
    (mk {
      name = "cvc5v1_0_8";
      exe = "${cvc5Binary}/bin/cvc5";
      inherit withSonolar;
    })
  ]))));

  evidence = linkFarm "evidence" (lib.mapAttrs (_: v: v.links) cases);
}
