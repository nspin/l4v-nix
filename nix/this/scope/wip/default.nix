{ lib
, pkgs
, stdenv
, callPackage
, runCommand
, writeText
, writeScript
, writeShellApplication
, linkFarm
, runtimeShell
, mkShell
, fetchFromGitHub
, breakpointHook
, bashInteractive
, strace
, gdb
, cntr

, scopeConfig
, overrideConfig
, l4vWith
, graphRefine
, graphRefineWith
, graphRefineSolverLists
, python2WithDebuggingSymbols

, this
, overrideScope
}:

let
  inherit (this) scopes;

  tmpSourceDir = ../../../../tmp/src;

  tmpSource = {
    seL4 = lib.cleanSource (tmpSourceDir + "/seL4");
    HOL = lib.cleanSource (tmpSourceDir + "/HOL");
    graph-refine = lib.cleanSource (tmpSourceDir + "/graph-refine");
  };

in rec {

  x = writeText "x"
    (toString
      (lib.flatten
        [
          this.scopes.ARM.withChannel.tip.upstream.cProofs
          this.scopes.ARM_HYP.withChannel.tip.upstream.cProofs
          this.scopes.AARCH64.withChannel.tip.upstream.cProofs
          this.scopes.RISCV64.withChannel.tip.upstream.cProofs
          this.scopes.RISCV64-MCS.withChannel.tip.upstream.cProofs
          this.scopes.X64.withChannel.tip.upstream.cProofs

          this.scopes.ARM.withChannel.release.upstream.cProofs
          this.scopes.ARM_HYP.withChannel.release.upstream.cProofs
          this.scopes.AARCH64.withChannel.release.upstream.cProofs
          this.scopes.RISCV64.withChannel.release.upstream.cProofs
          # this.scopes.RISCV64-MCS.withChannel.release.upstream.cProofs
          this.scopes.X64.withChannel.release.upstream.cProofs
        ]
      )
    );

  keep = writeText "keep" (toString (lib.flatten [
    # this.scopes.arm.legacy.o1.all
    # this.displayStatus

    (lib.forEach (map this.mkScopeFomNamedConfig this.namedConfigs) (scope:
      [
        (if scope.scopeConfig.mcs || lib.elem scope.scopeConfig.arch [ "AARCH64" "X64" ] then scope.slow else scope.slower)
      ]
    ))
  ]));

  xxx = writeText "x" (toString (lib.flatten [
    (lib.forEach (map this.mkScopeFomNamedConfig this.namedConfigs) (scope: [
      (
        lib.optionals (!scope.scopeConfig.mcs) [
          (
            if scope.scopeConfig.arch == "AARCH64" || scope.scopeConfig.arch == "X64"
            then scope.slower
            else scope.slow
          )
        ]
      )
    ]))
  ]));

  a = writeText "a" (toString (lib.flatten [
    (lib.forEach (map this.mkScopeFomNamedConfig this.namedConfigs) (scope:
      [
        (if scope.scopeConfig.mcs || lib.elem scope.scopeConfig.arch [ "AARCH64" "X64" ] then scope.slow else scope.slower)
      ]
    ))
  ]));

  o2 = scopes.arm.legacy.o2;
  o2w = o2.wip;
  rm = scopes.riscv64.mcs.o1;
  rmt = rm.graphRefine.all.targetDir;

  stackBounds = graphRefineWith {
    name = "stack-bounds";
    args = graphRefine.saveArgs;
  };

  o1bad = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      # "verbose"
      "trace-to:report.txt"
      "init_freemem"
    ];
    stackBounds = "${stackBounds}/StackBounds.txt";
  };

  o2c = o2.graphRefineWith {
    args = o2.graphRefine.saveArgs ++ [
      "trace-to:report.txt"
      "-exclude"
        "init_freemem"
        "decodeARMMMUInvocation"
      "-end-exclude"
      "coverage"
    ];
  };

  o2a = o2.graphRefineWith {
    args = o2.graphRefine.saveArgs ++ [
      "trace-to:report.txt"
      "-exclude"
        "init_freemem"
        "decodeARMMMUInvocation"
      "-end-exclude"
      "all"
    ];
  };

  es = o2w.es_;
  es_ = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      "verbose"
      # "trace-to:report.txt"

      # "emptySlot"
      # "setupCallerCap"
      # "invokeTCB_WriteRegisters"
      # "makeUserPDE"
      "lookupSourceSlot" # x
      # "loadCapTransfer" # x
      # "Arch_maskCapRights" # x
      # "map_kernel_frame"
    ];
    solverList = debugSolverList;
    keepBigLogs = true;
    stackBounds = "${stackBounds}/StackBounds.txt";
    source = tmpSource.graph-refine;
  };

    # extraNativeBuildInputs = [
    #   breakpointHook
    #   bashInteractive
    # ];

  debugSolverList =
    let
      chosen = "yices";
      # chosen = "bitwuzla";
      scope = graphRefineSolverLists.overrideScope (self: super: {
        executables = lib.flip lib.mapAttrs super.executables (lib.const (old: [ wrapSolver "trace" ] ++ old));
        # executables = lib.flip lib.mapAttrs super.executables (k: v:
        #   (if k == chosen then [ wrap "trace" ] else []) ++ v
        # );
        # onlineSolver = {
        #   command = self.onlineCommands.${chosen};
        #   inherit (super.onlineSolver) config;
        # };
        # offlineSolverKey = {
        #   attr = chosen;
        #   inherit (super.offlineSolverKey) granularity;
        # };
        offlineSolverFilter = attr: lib.optionals (attr == chosen) [
          self.granularities.machineWord
          # self.granularities.byte
        ];
      });
    in
      scope.solverList;

  wrapSolver = writeScript "wrap" ''
    #!${runtimeShell}

    set -u -o pipefail

    parent="$1"
    shift

    t=$(date +%s.%6N)
    d=$parent/$t

    mkdir -p $d

    echo $t >&2

    echo $$ > $d/wrapper-pid.txt
    echo "$@" > $d/args.txt

    exec < <(tee $d/in.smt2) > >(tee $d/out.smt2) 2> >(tee $d/err.log >&2)

    bash -c 'echo $$ > solver-pid.txt && exec "$@"' -- "$@"

    ret=$?

    echo $ret > $d/ret.txt

    exit $ret
  '';

  gdbShell = mkShell {
    nativeBuildInputs = [
      gdb
    ];

    script = "${python2WithDebuggingSymbols}/share/gdb/libpython.py";

    shellHook = ''
      d() {
        pid="$1"
        sudo gdb -p "$pid" -x "$script"
      }
    '';
  };

  scopeWithHol4Rev = { rev, ref ? "HEAD" }: overrideConfig {
    hol4Source = lib.cleanSource (builtins.fetchGit {
      url = "https://github.com/coliasgroup/HOL";
      inherit rev ref;
    });
  };
}
