{ lib
, pkgs
, callPackage
, runCommand
, writeText
, writeScript
, writeShellApplication
, linkFarm
, runtimeShell
, breakpointHook
, bashInteractive
, strace

, scopeConfig
, l4vWith
, graphRefine
, graphRefineWith
, graphRefineSolverLists

, this
, overrideScope
}:

let
  tmpSource = lib.cleanSource ../../../../tmp/graph-refine;

in rec {

  d = graphRefineWith {
    source = tmpSource;
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "init_freemem"
    ];
  };

  allExceptInitFreemem = graphRefineWith {
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "-exclude"
        "init_freemem"
      "-end-exclude"
      "all"
    ];
  };

  justMemzero = graphRefineWith {
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "memzero"
    ];
  };

  justInitFreemem = graphRefineWith {
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "init_freemem"
    ];
  };

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

  evidenceScopes = {
    at120 = scopeWithHOL4Rev { rev = "6c0c2409ecdbd7195911f674a77bfdd39c83816e"; };
    at121 = scopeWithHOL4Rev { rev = "ab03cec5200c8b23f9ba60c5cea958cfcd0cd158"; };
    good = scopeWithHOL4Rev { rev = "6d809bfa2ef8cbcb75d63317c4f8f2e1a6a836ed"; };
    bad = scopeWithHOL4Rev { rev = "bd30aea4dae85d51001ea398c59d2459a3e57dc6"; };
    current = scopeWithHOL4Rev rec {
      rev = "39606aea49bbfef131fcad2af088800e4b048da3";
      ref = "refs/tags/keep/${builtins.substring 0 32 rev}";
    };
  };

  evidence = linkFarm "evidence" (lib.flip lib.mapAttrs evidenceScopes (_: scope:
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
          hol4Source = lib.cleanSource (builtins.fetchGit {
            url = "https://github.com/nspin/HOL";
            ref = "pr/fix-arm-step-lib-for-disjnorm";
            inherit rev;
          });
        };
      })).hol4;
    in {
      before = f "4954936b88855c6857edc273d4bf60189e311d85";
      after = f "2446310e6cffcf46249b7706d5ceffc0a1c49b33";
    };

  kernels = writeText "x" (toString (this.mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals (lib.all lib.id [
        (lib.elem scope.scopeConfig.arch [
          "ARM"
        ])
      ]) [
        scope.kernel
      ]
  )));

  keep = writeText "keep" (toString (lib.flatten [
    # seL4_12_0_0.graphRefine.all
    kernels
    allExceptInitFreemem
    # evidence
    # hol4PR.before
    # hol4PR.after
  ]));

  prime = writeText "prime" (toString (lib.flatten [
    allExceptInitFreemem
    this.byConfig.arm.gcc10.o2.wip.allExceptInitFreemem

    # seL4_12_0_0.graphRefine.all
    # evidence
    # hol4PR.after
    # hol4PR.before
  ]));
}
