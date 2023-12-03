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
    };
  });

  hs = r12.l4vWith {
    tests = [
      "HaskellKernel"
    ];
  };

  prime = writeText "prime" (toString (lib.flatten [
    all
  ]));

  # gcc49GraphRefineInputs =
  #   lib.forEach (lib.attrNames this.optLevels)
  #     (optLevel: this.byConfig.arm.gcc49.${optLevel}.graphRefineInputsViaMake);

  all = this.mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = this.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in
      lib.optionals scope.scopeConfig.bvSupport [
        scope.graphRefine.demo
      ]
  );

}
