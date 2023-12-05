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
          "memzero"
          # "-exclude"
          #   "init_freemem"
          # "-end-exclude"
          # "all"
        ];
      };
    in
      runCommand "summary" {
        passthru = {
          inherit run;
        };
      } ''
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
    a = f "464d1d1202b6346a4d8487950408544aec4f3389"; # bad
    mb = f "16846f9e05c84636d8bfd91298a70ef027040f73"; # good
    mer = f "ec86d1ca16156f00edae83594988a957c8ff4b99"; # bad
    op = f "fd26642e95039121ff282174d9113f1bd9386e2f"; # bad
    merb2 = f "f95c3d726a80b80aecd056966ec07d66a2beda18"; # good
  };

  y = {
    y1 = f "191f43f4fa8e735dfc9a7fe9feb50dae25e1048a"; # bad
    y2 = f "9b84a1fde534aab7a716e621ea011a7d8188d7be"; # good
    y3 = f "f8ad83efa9d8ea2344e5b67bc06a8970b79e8cd2"; # good
    y4 = f "d188bb043305bef02ffc770fbb9c9d657a2d1aa0"; # bad
    y5 = f "9f1e6b692e075aee80e9f58e590ce929699c829f"; # bad
  };

  # From 9f1e6b692e075aee80e9f58e590ce929699c829f (bad)

  # https://github.com/HOL-Theorem-Prover/HOL/issues/609

  # first disjnorm commit:
  # 4875b1b60d4ee6357932f6ca7e384107130d1169

  # last disjorm merge:
  # 97cd72e1ce58b888b52153ca5ed025fa97820876

  # git log seL4-12.0.0..seL4-12.1.0 --graph

  z1 = {
    x1 = f "56eb8cb294e62f57600b94fc836e07fbcaea1928"; # bad
    x2 = f "94c0018eeb56544fd9797ea3bd403c7b0357790d"; # bad (Jul 23 2020)
    # x3 = f "b268ea121de2252e00172169281cc1f6aac071b4";
  };

  z2 = {
    # x4 = f "3ec1136e48d82d77e1f2280b1133988520dd6ee5"; # fail
    # x5 = f "34a7a9b6b4eacdd295f278782359c3be7810727a"; # fail
  };

  z3 = {
    # x6 = f "89e07c5a43c0637bc614b4396e6a8b3cb902cedb"; # ? # other parent of commit linked at end of https://github.com/HOL-Theorem-Prover/HOL/issues/609
    # x7 = f "53a2a87362930e08c64eb2e030a10c92c0b3b45e"; # ? # (not worth, is parent of 12.0.0) # anchor of disjnorm

    # on disjnorm
    x8 = f "dcd235c4e88e3465077ae2efe18dd9964b7f6332"; # bad

    # anchor of disjnorm
    x9 = f "53a2a87362930e08c64eb2e030a10c92c0b3b45e"; # good?
  };

  # from git log seL4-12.0.0..94c0018eeb56544fd9797ea3bd403c7b0357790d --merges:
  z4 = {
    x1 = f "b268ea121de2252e00172169281cc1f6aac071b4";
    x2 = f "2809015377f873ada95535e89b801a87c05eda9c";
    x3 = f "98775dbc8a019b522bd9e7d08e24c75cd6f27a9a";
    x4 = f "3f7c783c43f82cb47d9f09e21916f96d3279aa7b";
  };

  xs = writeText "xs" (toString (lib.attrValues x));
  ys = writeText "ys" (toString (lib.attrValues y));
  z1s = writeText "z1s" (toString (lib.attrValues z1));
  z2s = writeText "z2s" (toString (lib.attrValues z2));
  z3s = writeText "z3s" (toString (lib.attrValues z3));
  z4s = writeText "z4s" (toString (lib.attrValues z4));

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
