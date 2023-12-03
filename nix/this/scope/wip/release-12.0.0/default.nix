{ lib
, pkgs
, callPackage
, runCommand
, writeText
, writeScript
, writeShellApplication
, runtimeShell
, breakpointHook
, bashInteractive
, strace

, sources
, graphRefine
, graphRefineWith
, graphRefineSolverLists

, this
}:

# NOTES
# - O0 and O2 stack bounds fail with multiple compiler versions
# - compiler versions similar overall
# - coverage fails for gcc8 but not gcc49
# - cvc4-1.6+ and cvc5 slow (esp cvc5)
# - cvc5 conversation problem
# - sonolar bug, mitigated by many solvers
# - seL4 12.0.0 and 11.0.0 have same issues
# - same issues using dockerhub images and nix

let
  tmpSource = lib.cleanSource ../../../../tmp/graph-refine;

in rec {
  wrap = writeScript "wrap" ''
    #!${runtimeShell}

    set -u -o pipefail

    parent="$1"
    shift

    t=$(date +%s.%6N)
    d=$parent/$t

    mkdir -p $d

    echo $t >&2

    echo $$ > $d/pid.txt
    echo "$@" > $d/args.txt

    "$@" < <(tee $d/in.smt2) > >(tee $d/out.smt2)
    ret=$?

    echo $ret > $d/ret.txt

    exit $ret
  '';

  failures = {

    decodeARMMMUInvocation = graphRefineWith {
      solverList = graphRefineSolverLists.experimental;
      targetDir = graphRefine.justStackBounds;
      args = [
        "trace-to:report.txt" "decodeARMMMUInvocation"
      ];
    };

    # Only fails with newer GCC versions?
    invokeTCB_WriteRegisters = graphRefineWith {
      solverList = graphRefineSolverLists.experimental;
      targetDir = graphRefine.justStackBounds;
      args = [
        "trace-to:report.txt" "invokeTCB_WriteRegisters"
      ];
    };

    create_kernel_untypeds = graphRefineWith {
      solverList = graphRefineSolverLists.experimental;
      targetDir = graphRefine.justStackBounds;
      args = [
        "trace-to:report.txt" "create_kernel_untypeds"
      ];
    };

    # Hangs. All solvers exit, only Python remains.
    init_freemem = graphRefineWith {
      solverList = graphRefineSolverLists.experimental;
      targetDir = graphRefine.justStackBounds;
      args = [
        "trace-to:report.txt" "init_freemem"
      ];
    };

    # Appears that search returns proof that fails check.
    handleInterruptEntry = graphRefineWith {
      # solverList = graphRefineSolverLists.experimental;
      solverList = graphRefineSolverLists.original;
      targetDir = graphRefine.justStackBounds;
      args = [
        "verbose"
        "trace-to:report.txt" "handleInterruptEntry"
      ];
    };

    # `memcpy` is just one example of this problem.
    memcpyWithOriginalSolverList = graphRefineWith {
      solverList = graphRefineSolverLists.original;
      targetDir = graphRefine.justStackBounds;
      args = [
        "trace-to:report.txt" "memcpy"
      ];
    };
  };

  allFailures = writeText "x" (toString (lib.attrValues failures));

  mostFailures = writeText "x" (toString (lib.attrValues {
    inherit (failures)
      decodeARMMMUInvocation
      invokeTCB_WriteRegisters
      create_kernel_untypeds
      handleInterruptEntry
      memcpyWithOriginalSolverList
      # init_freemem # hangs
    ;
  }));

  most = graphRefineWith {
    solverList = graphRefineSolverLists.experimental;
    targetDir = graphRefine.justStackBounds;
    args = [
      "trace-to:report.txt"
      "-exclude"
        "create_kernel_untypeds" # fails
        "init_freemem" # hangs
      "-end-exclude"
      "all"
    ];
  };

  # very wip
  check = graphRefineWith rec {
    source = tmpSource; # branch nspin/wip/load-proofs
    targetDir = graphRefine.justStackBounds;
    args = [
      # "verbose"
      "trace-to:report.txt"
      "use-proofs-of:${graphRefine.demo}/proofs.txt"
      # "deps:Kernel_C.cancelAllIPC"
    ];
  };

  prime = writeText "prime" (toString (lib.flatten [
    mostFailures
    gcc49GraphRefineInputs
    # allGraphRefineInputs
  ]));

  gcc49GraphRefineInputs =
    lib.forEach (lib.attrNames this.optLevels)
      (optLevel: this.byConfig.arm.gcc49.${optLevel}.graphRefineInputsViaMake);

  allGraphRefineInputs = this.mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals scope.scopeConfig.bvSupport [
        scope.graphRefineInputsViaMake
      ]
  );

  debug = runCommand "x" {
    nativeBuildInputs = [
      bashInteractive
      breakpointHook
    ];
  } ''
    export FOO=bar

    false
  '';
}

# source = tmpSource;
# source = graphRefineSource;
# solverList = graphRefineSolverLists.experimental;
# solverList = with graphRefineSolverLists; writeText "solverlist" ''
#   CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=0
#   Other: offline: ${z3Exe} -in
# '';
# extraNativeBuildInputs = [
#   strace
# ];
# commands = ''
#   (strace -f -e 'trace=!all' python2 ${source}/graph-refine.py . ${lib.concatStringsSep " " args} 2>&1 || true) | tee log.txt
# '';
