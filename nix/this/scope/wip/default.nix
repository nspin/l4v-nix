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
      hol4Source = lib.cleanSource (builtins.fetchGit {
        url = "https://github.com/seL4/HOL";
        rev = "6c0c2409ecdbd7195911f674a77bfdd39c83816e";
      });
      graphRefineSource = lib.cleanSource (builtins.fetchGit {
        url = "https://github.com/seL4/graph-refine";
        rev = "946bf9c6e7bd8eeb4aecc60ad567663d37af86b7"; # coliasgroup/verification-reproducability-release-12.0.0
      });
      isabelleVersion = "2020";
      stackLTSAttr = "lts_13_15";
      targetCCWrapperAttr = "gcc49";
    };
  });

  h121 = overrideScope (self: super: {
    scopeConfig = super.scopeConfig.override {
      # From manifest at seL4-12.1.0
      hol4Source = lib.cleanSource (builtins.fetchGit {
        url = "https://github.com/seL4/HOL";
        rev = "ab03cec5200c8b23f9ba60c5cea958cfcd0cd158";
      });
    };
  });

  scopeWithHOL4Rev = rev: overrideScope (self: super: {
    scopeConfig = super.scopeConfig.override {
      # From manifest at seL4-12.1.0
      hol4Source = lib.cleanSource (builtins.fetchGit {
        url = "https://github.com/seL4/HOL";
        inherit rev;
      });
    };

    hol4Rev = rev;
  });

  cs = checkpointScopes;

  checkpointScopes = {
    h120 = scopeWithHOL4Rev "6c0c2409ecdbd7195911f674a77bfdd39c83816e";
    h121 = scopeWithHOL4Rev "ab03cec5200c8b23f9ba60c5cea958cfcd0cd158";
    good = scopeWithHOL4Rev "6d809bfa2ef8cbcb75d63317c4f8f2e1a6a836ed";
    bad = scopeWithHOL4Rev "bd30aea4dae85d51001ea398c59d2459a3e57dc6";
    sdcr = scopeWithHOL4Rev "553e7165b4d27ecda9b69913728e93f8f3f7b891";
    upstream = overrideScope (self: super: {
      scopeConfig = super.scopeConfig.override {
        hol4Source = lib.cleanSource (builtins.fetchGit {
          url = "https://github.com/HOL-Theorem-Prover/HOL.git";
          rev = self.hol4Rev;
        });
      };
      hol4Rev = "3f6e78258b82149b95ab354e180b95cd094ec4e7";
    });
  };

  checkpoint = linkFarm "checkpoint" (lib.flip lib.mapAttrs checkpointScopes (_: scope:
    linkFarm "scope" (
      {
        "rev" = writeText "rev.txt" scope.hol4Rev;
        "kernel.elf.txt" = "${scope.kernel}/kernel.elf.txt";
        "kernel.sigs" = "${scope.kernel}/kernel.sigs";
        "kernel_mc_graph.txt" = "${scope.decompilation}/kernel_mc_graph.txt";
        "log.txt" = "${scope.decompilation}/log.txt";
        "report.txt" = "${scope.wip.justMemzero}/report.txt";
      }
    )
  ));
  # allExceptInitFreemem

  keep = writeText "kleep" (toString (lib.flatten [
    r12.graphRefine.all
    # graphRefine.all
    allExceptInitFreemem
    h121.wip.allExceptInitFreemem
    kernels
    xs
  ]));

  kernels = writeText "x" (toString (this.mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals (lib.all lib.id [
        (lib.elem scope.scopeConfig.arch [
          "ARM"
        ])
      ])
      [
        scope.kernel
      ]
  )));

  prime = writeText "prime" (toString (lib.flatten [
  ]));

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
      # "deps:Kernel_C.init_freemem"
      "init_freemem"
    ];
  };

  # gcc49GraphRefineInputs =
  #   lib.forEach (lib.attrNames this.optLevels)
  #     (optLevel: this.byConfig.arm.gcc49.${optLevel}.graphRefineInputsViaMake);

  # all = this.mkAggregate (
  #   { archName, targetCCWrapperAttrName, optLevelName }:
  #   let
  #     scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
  #   in
  #     lib.optionals scope.scopeConfig.bvSupport [
  #       scope.graphRefine.demo
  #     ]
  # );

}
