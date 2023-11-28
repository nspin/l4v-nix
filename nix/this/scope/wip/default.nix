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
# - figure out why cvc5 throws ConversationProblem
#
# TODO(later)
# - z3 offline

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
# commands = ''
#   (strace -f -e 'trace=!all' python2 ${source}/graph-refine.py . ${lib.concatStringsSep " " args} 2>&1 || true) | tee log.txt
# '';
