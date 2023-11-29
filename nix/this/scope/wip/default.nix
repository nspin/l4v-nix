{ lib
, pkgs
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
, sonolarBinary
, cvc4Binary

, this
}:

# TODO(now)
# - coverage fails for gcc8 but not gcc49
# - stack check fails for all but -O1
# - cvc5 throws ConversationProblem
#
# TODO(later)
# - use mathsat4 as offline solver
# - use z3 as offline solver

let
  inherit (graphRefineSolverLists) selectedCVC4Binary;

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

  debug = runCommand "x" {
    nativeBuildInputs = [
      bashInteractive
      breakpointHook
    ];
  } ''
    export FOO=bar

    false
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
      "skip-proofs-of:${./resources/misc-logs/all-1.log}"
      "-exclude"
        "create_kernel_untypeds" # fails
        "init_freemem" # hangs
      "-end-exclude"
      "all"
    ];
  };

  # very wip
  check = graphRefineWith rec {
    source = lib.cleanSource ../../../../tmp/graph-refine;
    targetDir = graphRefine.justStackBounds;
    args = [
      # "verbose"
      "trace-to:report.txt"
      "use-proofs-of:${graphRefine.demo}/proofs.txt"
      "deps:Kernel_C.cancelAllIPC"
    ];
  };

  # very wip
  decodeARMMMUInvocation = graphRefineWith rec {
    source = lib.cleanSource ../../../../tmp/graph-refine;
    solverList = with graphRefineSolverLists; new;
    # solverList = with graphRefineSolverLists; writeText "solverlist" ''
    #   CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=5000
    #   CVC4: offline: ${cvc4BinaryExe} --lang smt
    #   CVC4-word8: offline: ${cvc4BinaryExe} --lang smt
    #     config: mem_mode = 8
    #   SONOLAR: offline: ${sonolarBinaryExe} --input-format=smtlib2
    #   SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
    #     config: mem_mode = 8
    #   Yices: offline: ${wrap} t32 ${yicesSmt2Exe}
    #   Yices-word8: offline: ${wrap} t8 ${yicesSmt2Exe}
    #     config: mem_mode = 8
    # '';
    targetDir = graphRefine.justStackBounds;
    args = [
      "verbose"
      "trace-to:report.txt"
      "skip-proofs-of:${./resources/logs-from-all/graph-refine-1.log}"
      "skip-proofs-of:${./resources/logs-from-all/graph-refine-2.log}"
      "skip-proofs-of:${./resources/logs-from-all/graph-refine-3.log}"
      # "deps:Kernel_C.decodeARMMMUInvocation"
      "-exclude"
        "Kernel_C.create_kernel_untypeds"
        "Kernel_C.init_freemem"
        "Kernel_C.invokeTCB_WriteRegisters"
      "-end-exclude"
      "all"
    ];
  };

  # old
  checkAllExceptFailing = graphRefineWith rec {
    solverList = graphRefineSolverLists.new;
    targetDir = graphRefine.justStackBounds;
    args = [
      "trace-to:report.txt"
      "skip-proofs-of:${./resources/logs-from-all/graph-refine-1.log}"
      "skip-proofs-of:${./resources/logs-from-all/graph-refine-2.log}"
      "skip-proofs-of:${./resources/logs-from-all/graph-refine-3.log}"
      "-exclude"
        "Kernel_C.create_kernel_untypeds"
        "Kernel_C.decodeARMMMUInvocation"
        "Kernel_C.init_freemem"
        "Kernel_C.invokeTCB_WriteRegisters"
      "-end-exclude"
      "all"
    ];
  };

  prime = writeText "x"
    (toString
      (lib.forEach (lib.attrNames this.optLevels)
        (optLevel: this.byConfig.arm.gcc49.${optLevel}.graphRefineInputs)));

  allGraphRefineInputs = writeText "x" (toString (this.mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals scope.l4vConfig.bvSupport [
        scope.graphRefineInputs
      ]
  )));

}

# source = lib.cleanSource ../../../../tmp/graph-refine;
# source = sources.graphRefine;
# extraNativeBuildInputs = [
#   strace
# ];
# solverList = with graphRefineSolverLists; writeText "solverlist" ''
#   CVC4: online: ${cvc4BinaryExe} --incremental --lang smt --tlimit=0
#   Other: offline: ${z3Exe} -in
# '';
# commands = ''
#   (strace -f -e 'trace=!all' python2 ${source}/graph-refine.py . ${lib.concatStringsSep " " args} 2>&1 || true) | tee log.txt
# '';
