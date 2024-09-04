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

  tmpSource = lib.cleanSource ../../../../tmp/graph-refine;

in rec {

  keep = writeText "keep" (toString (lib.flatten [
    this.scopes.arm.legacy.o1.all
    this.displayStatus

    (lib.forEach (map this.mkScopeFomNamedConfig this.namedConfigs) (scope:
      [
      ] ++ lib.optionals (
        !(scope.scopeConfig.arch == "X64" && scope.scopeConfig.optLevel == "-O1")
      ) [
        scope.kernel
      ] ++ lib.optionals (
        scope.scopeConfig.arch != "X64" && scope.scopeConfig.features == ""
      ) [
        scope.l4vAll
      ] ++ lib.optionals (
        scope.scopeConfig.bvSupport && scope.scopeConfig.features == ""
      ) [
        scope.graphRefine.everythingAtOnce.preTargetDir
      ]
    ))
  ]));

  a = writeText "a" (toString (lib.flatten [
    (lib.forEach (map this.mkScopeFomNamedConfig this.namedConfigs) (scope:
      [
      ] ++ lib.optionals (
        scope.scopeConfig.features == "MCS"
      ) [
        scope.l4vAll
        scope.graphRefine.everythingAtOnce.preTargetDir
      ]
    ))
  ]));

  axel = scopes.riscv64.mcs.o1.overrideScope (self: super: {
    scopeConfig = super.scopeConfig.override {
      # seL4Source = fetchFromGitHub {
      #   owner = "axel-h";
      #   repo = "seL4";
      #   rev = "6b3d9b43310e3af7ff8c367c7a44f5f7b3892a21";
      #   hash = "sha256-UY3jGX6Z4eg9WPUlycl+ZSMocLfudvIjnaiZ1XBZS7Q=";
      # };

      seL4Source = builtins.fetchGit {
        url = "https://github.com/seL4/seL4";
        rev = "b7ad2e0c669b5648ff32a9bb0dbc56337ec1ac77";
      };
      l4vSource = builtins.fetchGit {
        url = "https://github.com/seL4/l4v";
        rev = "9b4c43614741c1a55f1461273e382a803e7efcb6";
        ref = "rt";
      };
    };
  });

  # z = axel.graphRefine.all.preTargetDir;
  z = scopes.riscv64.mcs.o1.graphRefine.all.preTargetDir;

  o2 = scopes.arm.legacy.o2;

  stackBounds = graphRefineWith {
    name = "stackb-bounds";
    args = graphRefine.saveArgs;
  };

  o1bad = graphRefineWith {
    name = "wip";
    args = graphRefine.saveArgs ++ [
      # "verbose"
      "trace-to:report.txt"
      "init_freemem"
    ];
    # stackBounds = ../../../../../tmp/sb/StackBounds.txt;
  };

  o2wip = graphRefineWith {
    name = "wip";
    args = graphRefine.saveArgs ++ [
      # "verbose"
      "trace-to:report.txt"
      "-exclude"
      "init_freemem"
      "decodeARMMMUInvocation"
      "-end-exclude"
      "coverage"
    ];
    # stackBounds = ../../../../../tmp/sb/StackBounds.txt;
  };

  d = graphRefineWith rec {
    source = tmpSource;
    # keepSMTDumps = true;
    # solverList = debugSolverList;
    # extraNativeBuildInputs = [
    #   breakpointHook
    #   bashInteractive
    # ];
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "init_freemem"
      # "decodeARMMMUInvocation"
    ];
  };

  x = this.scopes.arm.legacy.o2.wip.d;

  justInitFreemem = graphRefineWith {
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "init_freemem"
    ];
  };

  justDecodeARMMMUInvocation = graphRefineWith {
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "decodeARMMMUInvocation"
    ];
  };

  allExceptNotWorkingForO2 = graphRefineWith {
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "-exclude"
        "init_freemem"
        "decodeARMMMUInvocation"
      "-end-exclude"
      "all"
    ];
  };

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

  debugSolverList =
    let
      # chosen = "yices";
      # chosen = "bitwuzla";
      scope = graphRefineSolverLists.overrideScope (self: super: {
        # executables = lib.flip lib.mapAttrs super.executables (lib.const (old: [ wrap "trace" ] ++ old));
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
      });
    in
      scope.solverList;

  wrap = writeScript "wrap" ''
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

  seL4_12_0_0 = overrideScope (self: super: {
    scopeConfig = super.scopeConfig.override {
      seL4Source = builtins.fetchGit {
        url = "https://github.com/seL4/seL4";
        rev = "dc83859f6a220c04f272be17406a8d59de9c8fbf";
      };
      l4vSource = builtins.fetchGit {
        url = "https://github.com/seL4/l4v";
        rev = "6700d97b7f0593dbf5d8145ee43f1e151553dea0";
      };
      hol4Source = builtins.fetchGit {
        url = "https://github.com/seL4/HOL";
        rev = "6c0c2409ecdbd7195911f674a77bfdd39c83816e";
      };
      isabelleVersion = "2020";
      stackLTSAttr = "lts_13_15";
      targetCCWrapperAttr = "gcc49";
    };
  });

  scopeWithHOL4Rev = { rev, ref ? "HEAD" }: overrideScope (self: super: {
    scopeConfig = super.scopeConfig.override {
      hol4Source = lib.cleanSource (builtins.fetchGit {
        url = "https://github.com/coliasgroup/HOL";
        inherit rev ref;
      });
    };
    hol4Rev = rev;
  });

  summaryScopes = {
    at120 = scopeWithHOL4Rev { rev = "6c0c2409ecdbd7195911f674a77bfdd39c83816e"; };
    at121 = scopeWithHOL4Rev { rev = "ab03cec5200c8b23f9ba60c5cea958cfcd0cd158"; };
    good = scopeWithHOL4Rev { rev = "6d809bfa2ef8cbcb75d63317c4f8f2e1a6a836ed"; };
    bad = scopeWithHOL4Rev { rev = "bd30aea4dae85d51001ea398c59d2459a3e57dc6"; };
    current = scopeWithHOL4Rev rec {
      rev = "39606aea49bbfef131fcad2af088800e4b048da3";
      ref = "refs/tags/keep/${builtins.substring 0 32 rev}";
    };
  };

  summary = linkFarm "summary" (lib.flip lib.mapAttrs summaryScopes (_: scope:
    linkFarm "scope" {
      "rev" = writeText "rev.txt" scope.hol4Rev;
      "kernel.elf.txt" = "${scope.kernel}/kernel.elf.txt";
      "kernel.sigs" = "${scope.kernel}/kernel.sigs";
      "kernel_mc_graph.txt" = "${scope.decompilation}/kernel_mc_graph.txt";
      "log.txt" = "${scope.decompilation}/log.txt";
      "report.txt" = "${scope.wip.justMemzero}/report.txt";
    }
  ));

  hol4PR =
    let
      f = rev: (overrideScope (self: super: {
        scopeConfig = super.scopeConfig.override {
          hol4Source = builtins.fetchGit {
            url = "https://github.com/nspin/HOL";
            ref = "pr/fix-arm-step-lib-for-disjnorm";
            inherit rev;
          };
        };
      })).hol4;
    in {
      before = f "4954936b88855c6857edc273d4bf60189e311d85";
      after = f "2446310e6cffcf46249b7706d5ceffc0a1c49b33";
    };

}
