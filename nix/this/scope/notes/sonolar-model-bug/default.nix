{ lib
, runCommand
, writeText
, writeScript
, runtimeShell

, graphRefine
, graphRefineSolverLists
, graphRefineWith
, sonolarBinary
}:

let
  inherit (graphRefineSolverLists) selectedCVC4Binary cvc4BinaryExe sonolarBinaryExe;

  wrap = writeScript "wrap" ''
    #!${runtimeShell}

    set -eu -o pipefail

    parent="$1"
    shift

    t=$(date +%s.%6N)
    d=$parent/$t

    mkdir -p $d

    echo $t >&2

    "$@" < <(tee $d/in.smt2) > >(tee $d/out.smt2)
  '';

in {
  dredge = graphRefineWith {
    solverList = writeText "solverlist" ''
      CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=0
      SONOLAR: offline: ${wrap} solver-logs ${sonolarBinaryExe} --input-format=smtlib2
    '';
    targetDir = graphRefine.justStackBounds;
    args = [
      "verbose" "trace-to:report.txt" "deps:Kernel_C.memcpy"
    ];
  };

  evidence =
    let
      d = ./resources;
      solvers = [ "sonolar" "cvc4" ];
      cmd = {
        sonolar = "sonolar --input-format=smtlib2";
        cvc4 = "cvc4 --lang smt";
      };
    in runCommand "evidence" {
      nativeBuildInputs = [
        selectedCVC4Binary
        sonolarBinary
      ];
    } ''
      exec 2>&1 > >(tee $out)

      ${lib.concatStrings
        (lib.flatten
          (lib.forEach solvers (solver: ''
            echo ">>> getting model from ${solver}"
            cat ${d + "/common.smt2"} ${d + "/get.smt2"} | ${cmd."${solver}"}
          ''))
        )
      }

      ${lib.concatStrings
        (lib.flatten
          (lib.forEach solvers (runSolver:
            lib.forEach solvers (useModelFromSolver: ''
              echo ">>> running ${runSolver} with model from ${useModelFromSolver}"
              cat ${d + "/common.smt2"} ${d + "/check-${useModelFromSolver}.smt2"} | ${cmd."${runSolver}"}
            '')
          ))
        )
      }
    '';
}
