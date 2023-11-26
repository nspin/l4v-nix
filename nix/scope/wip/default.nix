{ lib
, writeText
, writeScript
, writeShellApplication
, runtimeShell
, strace

, graphRefineWith
, graphRefineSolverLists
}:

# TODO
# - tune
# - figure out why are cvc4 >= 1.6 and cvc5 so slow
# - figure out why cvc5 throws ConversationProblem
# - figure out apparent buf in cvc4 1.5 and sonolar (assert self.parallel_solvers)
# - z3 offline

let
  wrap = writeScript "wrap" ''
    #!${runtimeShell}

    set -u -o pipefail

    t=$(date +%s.%6N)
    d=tmp/tlogs/$t

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
    name = "wip1";
    # solverList = graphRefineSolverLists.wip1;
    # solverList = graphRefineSolverLists.wip3;
    solverList = graphRefineSolverLists.wip4;
    targetDir = graphRefine.justStackBounds;
    # source = lib.cleanSource ../../tmp/graph-refine;
    args = [
      "verbose" "trace-to:report.txt" "deps:Kernel_C.memcpy"
    ];
  };

  b = graphRefineWith rec {
    name = "wip2";
    # solverList = graphRefineSolverLists.new;
    # solverList = graphRefineSolverLists.wip2;
    # solverList = graphRefineSolverLists.wip3;
    solverList = graphRefineSolverLists.wip4;
    targetDir = graphRefine.justStackBounds;
    source = lib.cleanSource ../../tmp/graph-refine;
    # source = sources.graphRefine;
    extraNativeBuildInputs = [
      strace
    ];
    # commands = ''
    #   (strace -f -e 'trace=!all' python2 ${source}/graph-refine.py . ${lib.concatStringsSep " " args} 2>&1 || true) | tee log.txt
    # '';
    args = [
      "verbose"
      "trace-to:report.txt"
      "skip-proofs-of:${../../notes/graph-refine-1.log}"
      "skip-proofs-of:${../../notes/graph-refine-2.log}"
      "skip-proofs-of:${../../notes/graph-refine-3.log}"
      # "-exclude"
        # "Kernel_C.create_kernel_untypeds"
        # "Kernel_C.decodeARMMMUInvocation"
        # "Kernel_C.init_freemem"
        # "Kernel_C.invokeTCB_WriteRegisters"
      # "-end-exclude"
      # "all"
      "deps:Kernel_C.init_freemem"
    ];
  };
}
