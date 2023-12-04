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

  r12 = overrideScope (self: super: {
    scopeConfig = super.scopeConfig.override {
      # seL4-12.0.0
      seL4Source = builtins.fetchGit {
        url = "https://github.com/seL4/seL4";
        rev = "dc83859f6a220c04f272be17406a8d59de9c8fbf";
      };
      l4vSource = builtins.fetchGit {
        url = "https://github.com/seL4/l4v";
        rev = "6700d97b7f0593dbf5d8145ee43f1e151553dea0";
      };
      isabelleVersion = "2020";
      stackLTSAttr = "lts_13_15";
      targetCCWrapperAttr = "gcc49";
    };
  });

  keep = writeText "kleep" (toString (lib.flatten [
    r12.graphRefine.all
    # graphRefine.all
    allExceptInitFreemem
    kernels
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
    name = "x";
    args = [
      "trace-to:report.txt"
      "save-proofs:proofs.txt"
      "-exclude"
        "init_freemem"
      "-end-exclude"
      "all"
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
