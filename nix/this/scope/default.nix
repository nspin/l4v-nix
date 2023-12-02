{ lib
, runCommand
, writeText
, texlive
, gcc9Stdenv
, mlton20180207
}:

{ l4vConfig
}:

self: with self; {

  inherit l4vConfig;

  ### sources ###

  projectsDir = ../../../projects;

  relativeToProjectsDir = path: projectsDir + "/${path}";

  rawSources = {
    seL4 = lib.cleanSource (relativeToProjectsDir "seL4");
    l4v = lib.cleanSource (relativeToProjectsDir "l4v");
    hol4 = lib.cleanSource (relativeToProjectsDir "HOL4");
    graphRefine = lib.cleanSource (relativeToProjectsDir "graph-refine");
    currentGraphRefine = lib.cleanSource (relativeToProjectsDir "current-graph-refine");

    graphRefineNoSeL4 = lib.cleanSourceWith ({
      src = rawSources.graphRefine;
      filter = path: type: builtins.match ".*/seL4-example/.*" path == null;
    });

    graphRefineJustSeL4 = lib.cleanSourceWith ({
      src = rawSources.graphRefine;
      filter = path: type: builtins.match ".*/seL4-example(/.*)?" path != null;
    });
  };

  sources = {
    inherit (rawSources)
      hol4
      graphRefine graphRefineNoSeL4 graphRefineJustSeL4
      currentGraphRefine
    ;
    seL4 = callPackage ./patched-sel4-source.nix {};
    l4v = callPackage ./patched-l4v-source.nix {};
  };

  ### tools and proofs ###

  kernelWithoutCParser = callPackage ./kernel.nix {
    withCParser = false;
  };

  kernelWithCParser = kernelWithoutCParser.override {
    withCParser = true;
  };

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
    buildStandaloneCParser = l4vConfig.bvSupport;
  };

  cProofs = l4vWith {
    name = "c-proofs";
    tests = [
      "CRefine"
    ] ++ lib.optionals l4vConfig.bvSupport [
      "SimplExportAndRefine"
    ];
    buildStandaloneCParser = l4vConfig.bvSupport;
  };

  justStandaloneCParser = l4vWith {
    name = "standalone-cparser";
    buildStandaloneCParser = true;
  };

  justSimplExport = l4vWith {
    name = "simpl-export";
    simplExport = l4vConfig.bvSupport;
  };

  minimalBinaryVerificationInputs = l4vWith {
    name = "minimal-bv-input";
    buildStandaloneCParser = true;
    simplExport = l4vConfig.bvSupport;
  };

  # binaryVerificationInputs = cProofs;
  binaryVerificationInputs = assert l4vConfig.bvSupport; minimalBinaryVerificationInputs;

  # standaloneCParser = binaryVerificationInputs;
  # simplExport = binaryVerificationInputs;

  standaloneCParser = justStandaloneCParser;
  simplExport = justSimplExport;

  hol4 = callPackage ./hol4.nix {};

  decompilation = callPackage ./decompilation.nix {};

  preprocessedKernelsAreIdentical = runCommand "preprocessed-kernels-are-identical" {} ''
    diff -q --ignore-matching-lines='^#' \
      ${kernelWithCParser}/kernel_all.c_pp \
      ${simplExport}/spec/cspec/c/build/${l4vConfig.arch}/kernel_all.c_pp

    touch $out
  '';

  cFunctionsTxt = "${simplExport}/proof/asmrefine/export/${l4vConfig.arch}/CFunDump.txt";

  asmFunctionsTxt = "${decompilation}/kernel_mc_graph.txt";

  graphRefineInputsViaMake = callPackage ./graph-refine-inputs-via-make.nix {};

  graphRefineSolverLists = callPackage ./graph-refine-solver-lists.nix {};

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefine = rec {
    justStackBounds = graphRefineWith {
      name = "just-stack-bounds";
    };

    functions = graphRefineWith {
      name = "functions";
      targetDir = justStackBounds;
      args = [
        "save:functions.txt"
      ];
    };

    coverage = graphRefineWith {
      name = "coverage";
      targetDir = justStackBounds;
      args = [
        "trace-to:coverage.txt" "coverage"
      ];
    };

    demo = graphRefineWith {
      name = "demo";
      targetDir = justStackBounds;
      args = [
        "trace-to:report.txt" "save-proofs:proofs.txt" "deps:Kernel_C.cancelAllIPC"
      ];
    };

    allWithSolverList = name: solverList: graphRefineWith {
      name = "all-with-solverlist-${name}";
      inherit solverList;
      targetDir = justStackBounds;
      args = [
        "trace-to:report.txt" "save-proofs:proofs.txt" "all"
      ];
    };

    allWithOriginalSolverList = allWithSolverList "original" graphRefineSolverLists.original;

    allWithNewSolverList = allWithSolverList "new" graphRefineSolverLists.new;

    all = allWithNewSolverList;
  };

  currentGraphRefineSolverLists = callPackage ./current-graph-refine-solver-lists.nix {};

  currentGraphRefineWith = callPackage ./current-graph-refine.nix {};

  currentGraphRefine = rec {
    functions = currentGraphRefineWith {
      name = "functions";
      args = [
        "save:functions.txt"
      ];
    };

    coverage = currentGraphRefineWith {
      name = "coverage";
      args = [
        "trace-to:coverage.txt" "coverage"
      ];
    };

    demo = currentGraphRefineWith {
      name = "demo";
      args = [
        "trace-to:report.txt" "save-proofs:proofs.txt" "deps:Kernel_C.cancelAllIPC"
      ];
    };

    all = currentGraphRefineWith {
      name = "all-with-solverlist";
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

  ghcWithPackagesForL4v = callPackage  ./deps/ghc-with-packages-for-l4v {};

  polyml58ForHol4 = callPackage ./deps/polyml-5.8-for-hol4.nix {};

  # polyml59ForHol4 = polyml;

  isabelle2020ForL4v = callPackage ./deps/isabelle-2020-for-l4v {};

  isabelleInitialHeaps = callPackage ./isabelle-initial-heaps.nix {};

  sonolarBinary = callPackage ./deps/solvers-for-graph-refine/sonolar-binary.nix {};
  cvc4BinaryFromIsabelle = callPackage ./deps/solvers-for-graph-refine/cvc4-binary-from-isabelle.nix {};
  cvc4Binary = callPackage ./deps/solvers-for-graph-refine/cvc4-binary.nix {};
  cvc5Binary = callPackage ./deps/solvers-for-graph-refine/cvc5-binary.nix {};
  mathsat5Binary = callPackage ./deps/solvers-for-graph-refine/mathsat5-binary.nix {};

  ### choices ###

  stdenvForHol4 = gcc9Stdenv;

  mlton = mlton20180207;

  polymlForHol4 = polyml58ForHol4;

  isabelleForL4v = isabelle2020ForL4v;

  ### aggregate ###

  slow = writeText "slow" (toString ([
    kernelWithCParser
    kernelWithoutCParser
    justStandaloneCParser
    justSimplExport
    minimalBinaryVerificationInputs
    l4vSpec
    hol4
  ] ++ lib.optionals l4vConfig.bvSupport [
    decompilation
    preprocessedKernelsAreIdentical
    graphRefineInputsViaMake
    graphRefine.justStackBounds
    graphRefine.functions
    graphRefine.coverage
    graphRefine.demo
    currentGraphRefine.functions
    currentGraphRefine.coverage
    currentGraphRefine.demo
    currentGraphRefine.all
    sonolarModelBug.evidence
    cvcVersions.evidence
  ]));

  slower = writeText "slower" (toString ([
    slow
    cProofs
    l4vAll
  ] ++ lib.optionals l4vConfig.bvSupport [
  ]));

  slowest = writeText "slowest" (toString ([
    slower
  ] ++ lib.optionals l4vConfig.bvSupport [
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
    # graphRefineInputsViaMake
  ]);

  cachedForAll = writeText "cached" (toString (
    # Fails only with X64-O1, all GCC versions
    lib.optionals (!(l4vConfig.arch == "X64" && l4vConfig.optLevel == "-O1")) [
      kernelWithoutCParser
    ]
  ));

  ### wip ###

  wip = callPackage ./wip {};
}
