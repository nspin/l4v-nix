{ lib
, runCommand
, writeText
, texlive
, gcc9Stdenv
, polyml
, mlton
, mlton20180207
, mlton20210107
}:

{ scopeConfig
}:

self: with self; {

  inherit scopeConfig;

  ### sources ###

  projectsDir = ../../../projects;

  relativeToProjectsDir = path: projectsDir + "/${path}";

  hol4Source = lib.cleanSource (relativeToProjectsDir "HOL4");
  graphRefineSource = lib.cleanSource (relativeToProjectsDir "graph-refine");

  patchedSeL4Source = callPackage ./patched-sel4-source {};
  patchedL4vSource = callPackage ./patched-l4v-source {};

  ### tools and proofs ###

  kernel = callPackage ./kernel.nix {};

  l4vWith = callPackage ./l4v.nix {};

  l4vSpec = l4vWith {
    name = "spec";
    tests = [
      "ASpec"
    ];
  };

  l4vAll = l4vWith {
    name = "all";
    tests = [];
    buildStandaloneCParser = scopeConfig.bvSupport;
  };

  cProofs = l4vWith {
    name = "c-proofs";
    tests = [
      "CRefine"
    ] ++ lib.optionals scopeConfig.bvSupport [
      "SimplExportAndRefine"
    ];
    buildStandaloneCParser = scopeConfig.bvSupport;
  };

  justStandaloneCParser = l4vWith {
    name = "standalone-cparser";
    buildStandaloneCParser = true;
  };

  justSimplExport = l4vWith {
    name = "simpl-export";
    simplExport = scopeConfig.bvSupport;
  };

  minimalBinaryVerificationInputs = l4vWith {
    name = "minimal-bv-input";
    buildStandaloneCParser = true;
    simplExport = scopeConfig.bvSupport;
  };

  # binaryVerificationInputs = cProofs;
  binaryVerificationInputs = assert scopeConfig.bvSupport; minimalBinaryVerificationInputs;

  # standaloneCParser = binaryVerificationInputs;
  # simplExport = binaryVerificationInputs;

  standaloneCParser = justStandaloneCParser;
  simplExport = justSimplExport;

  hol4 = callPackage ./hol4.nix {};

  decompilation = callPackage ./decompilation.nix {};

  preprocessedKernelsAreEquivalent = callPackage ./preprocessed-kernels-are-equivalent.nix {};

  cFunctionsTxt = "${simplExport}/proof/asmrefine/export/${scopeConfig.arch}/CFunDump.txt";

  asmFunctionsTxt = "${decompilation}/kernel_mc_graph.txt";

  graphRefineSolverLists = callPackage ./graph-refine-solver-lists.nix {};

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefine = rec {
    functions = graphRefineWith {
      name = "functions";
      args = [
        "save:functions.txt"
      ];
    };

    coverage = graphRefineWith {
      name = "coverage";
      args = [
        "trace-to:coverage.txt" "coverage"
      ];
    };

    demo = graphRefineWith {
      name = "demo";
      args = [
        "trace-to:report.txt" "save-proofs:proofs.txt" "deps:Kernel_C.cancelAllIPC"
      ];
    };

    all = graphRefineWith {
      name = "all";
      args = [
        "trace-to:report.txt" "save-proofs:proofs.txt" "all"
      ];
    };
  };

  ### notes ###

  sonolarModelBug = callPackage ./notes/sonolar-model-bug {};
  cvcVersions = callPackage ./notes/cvc-versions {};

  ### deps ###

  texliveEnv = with texlive; combine {
    inherit
      collection-fontsrecommended
      collection-latexextra
      collection-metapost
      collection-bibtexextra
      ulem
    ;
  };

  ghcWithPackagesForL4vByLTS = callPackage  ./deps/ghc-with-packages-for-l4v {};

  withMLton = mlton: lib.extendDerivation true { inherit mlton; };

  isabelle2020ForL4v = withMLton mlton20180207 (callPackage ./deps/isabelle-for-l4v/2020 {});
  isabelle2023ForL4v = withMLton mlton20210107 (callPackage ./deps/isabelle-for-l4v/2023 {});

  sonolarBinary = callPackage ./deps/solvers-for-graph-refine/sonolar-binary.nix {};
  cvc4BinariesFromIsabelle = callPackage ./deps/solvers-for-graph-refine/cvc4-binaries-from-isabelle.nix {};
  cvc4Binaries = callPackage ./deps/solvers-for-graph-refine/cvc4-binaries.nix {};
  cvc5Binary = callPackage ./deps/solvers-for-graph-refine/cvc5-binary.nix {};
  mathsat5Binary = callPackage ./deps/solvers-for-graph-refine/mathsat5-binary.nix {};

  ### choices ###

  stdenvForHol4 = gcc9Stdenv;

  mltonForHol4 = mlton;

  polymlForHol4 = lib.overrideDerivation polyml (attrs: {
    configureFlags = [ "--enable-shared" ];
  });

  isabelleForL4v = {
    "2020" = isabelle2020ForL4v;
    "2023" = isabelle2023ForL4v;
  }.${scopeConfig.isabelleVersion};

  ghcWithPackagesForL4v = ghcWithPackagesForL4vByLTS.${scopeConfig.stackLTSAttr};

  ### aggregate ###

  slow = writeText "slow" (toString ([
    kernel
    justStandaloneCParser
    justSimplExport
    minimalBinaryVerificationInputs
    l4vSpec
    hol4
  ] ++ lib.optionals scopeConfig.bvSupport [
    decompilation
    preprocessedKernelsAreEquivalent
    graphRefine.functions
    graphRefine.coverage
    graphRefine.demo
    graphRefine.all
    sonolarModelBug.evidence
    # cvcVersions.evidence # broken since removal of old graph-refine
  ]));

  slower = writeText "slower" (toString ([
    slow
    cProofs
    l4vAll
  ] ++ lib.optionals scopeConfig.bvSupport [
  ]));

  slowest = writeText "slowest" (toString ([
    slower
  ] ++ lib.optionals scopeConfig.bvSupport [
    graphRefine.all
  ]));

  all = writeText "all" (toString [
    slowest
  ]);

  cachedForPrimary = writeText "cached" (toString [
    # slow
    slower
  ]);

  cachedWhenBVSupport = writeText "cached" (toString [
  ]);

  cachedForAll = writeText "cached" (toString (
    # Fails only with X64-O1 (all GCC versions)
    lib.optionals (!(scopeConfig.arch == "X64" && scopeConfig.optLevel == "-O1")) [
      kernel
    ]
  ));

  ### wip ###

  wip = callPackage ./wip {};
}
