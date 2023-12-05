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

# NOTES
# - HOL4 at seL4-12.0.0 works (~25 skipped) for both seL4 12.0.0 and current
# - HOL4 at seL4-12.1.0 and beyond don't work (~125 skipped) for both seL4 12.0.0 and current

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
  });

  testHOL4Rev = rev:
    let
      scope = scopeWithHOL4Rev rev;
      run = scope.graphRefineWith {
        args = [
          "trace-to:report.txt"
          "save-proofs:proofs.txt"
          "-exclude"
            "init_freemem"
          "-end-exclude"
          "all"
        ];
      };
    in
      runCommand "summary" {} ''
        tail ${run}/report.txt > $out
        echo >> $out
        echo "out: ${run}" >> $out
        echo >> $out
        echo "rev: ${rev}" >> $out
      '';

  f = testHOL4Rev;

  x = {
    r120 = f "6c0c2409ecdbd7195911f674a77bfdd39c83816e"; # good
    r121 = f "ab03cec5200c8b23f9ba60c5cea958cfcd0cd158"; # bad
    exampleChanges = f "dcd235c4e88e3465077ae2efe18dd9964b7f6332"; # bad
    commonAncestor = f "6c081713c2712205fd8b325b55a31207ec3b7a8d"; # good
    a = f "464d1d1202b6346a4d8487950408544aec4f3389";
    mb = f "16846f9e05c84636d8bfd91298a70ef027040f73";
  };

  xs = writeText "xs" (toString (lib.attrValues x));

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
