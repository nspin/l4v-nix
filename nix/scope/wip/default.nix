{ lib
, runCommand
, writeText
, writeScript
, writeShellApplication
, runtimeShell
, strace

, sources
, graphRefine
, graphRefineWith
, graphRefineSolverLists
, sonolarBinary
}:

# TODO
# - tune
# - figure out why are cvc4 >= 1.6 and cvc5 so slow
# - figure out why cvc5 throws ConversationProblem
# - figure out apparent buf in cvc4 1.5 and sonolar (assert self.parallel_solvers)
# - z3 offline

let
  inherit (graphRefineSolverLists) selectedCvc4Binary;

  graohRefineSource = sources.graphRefine;

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

in {
  a = graphRefineWith {
    solverList = with graphRefineSolverLists; writeText "solverlist" ''
      CVC4: online: ${wrap} tlogs/online ${cvc4BinaryExe} --incremental --lang smt --tlimit=0
      SONOLAR: offline: ${wrap} tlogs/offline ${sonolarBinaryExe} --input-format=smtlib2
      # CVC4: offline: ${wrap} tlogs/offline ${cvc4BinaryExe} --lang smt
      # SONOLAR-word8: offline: ${sonolarBinaryExe} --input-format=smtlib2
        # config: mem_mode = 8
    '';
    targetDir = graphRefine.justStackBounds;
    # source = lib.cleanSource ../../tmp/graph-refine;
    args = [
      "verbose" "trace-to:report.txt" "deps:Kernel_C.memcpy"
    ];
  };

  b = graphRefineWith rec {
    solverList = graphRefineSolverLists.new;
    targetDir = graphRefine.justStackBounds;
    args = [
      "trace-to:report.txt"
      "skip-proofs-of:${./artifacts/logs-from-all/graph-refine-1.log}"
      "skip-proofs-of:${./artifacts/logs-from-all/graph-refine-2.log}"
      "skip-proofs-of:${./artifacts/logs-from-all/graph-refine-3.log}"
      "-exclude"
        "Kernel_C.create_kernel_untypeds"
        "Kernel_C.decodeARMMMUInvocation"
        "Kernel_C.init_freemem"
        "Kernel_C.invokeTCB_WriteRegisters"
      "-end-exclude"
      "all"
    ];
  };

  repro = runCommand "x" {
    nativeBuildInputs = [
      graphRefineSolverLists.selectedCvc4Binary
      sonolarBinary
    ];
  } ''
    echo !!! A
    sonolar --input-format=smtlib2 < ${./artifacts/sonolar-bug-repro/a.smt2}
    echo !!! B
    sonolar --input-format=smtlib2 < ${./artifacts/sonolar-bug-repro/b.smt2}
  '';

  # b = graphRefineWith rec {
  #   name = "wip-b";
  #   # solverList = graphRefineSolverLists.sb;
  #   # solverList = graphRefineSolverLists.wip4;
  #   solverList = graphRefineSolverLists.new;
  #   targetDir = graphRefine.justStackBounds;
  #   # source = lib.cleanSource ../../tmp/graph-refine;
  #   # source = sources.graphRefine;
  #   # extraNativeBuildInputs = [
  #   #   strace
  #   # ];
  #   # commands = ''
  #   #   (strace -f -e 'trace=!all' python2 ${source}/graph-refine.py . ${lib.concatStringsSep " " args} 2>&1 || true) | tee log.txt
  #   # '';
  #   args = [
  #     # "verbose"
  #     "trace-to:report.txt"
  #     "skip-proofs-of:${./notes/graph-refine-1.log}"
  #     "skip-proofs-of:${./notes/graph-refine-2.log}"
  #     "skip-proofs-of:${./notes/graph-refine-3.log}"
  #     "-exclude"
  #       "Kernel_C.create_kernel_untypeds"
  #       "Kernel_C.decodeARMMMUInvocation"
  #       "Kernel_C.init_freemem"
  #       "Kernel_C.invokeTCB_WriteRegisters"
  #     "-end-exclude"
  #     "all"
  #     # "deps:Kernel_C.init_freemem"
  #   ];
  # };
}
