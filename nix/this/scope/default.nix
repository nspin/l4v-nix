{ lib
, stdenv
, runCommand
, writeText
, texlive
, gcc9Stdenv
, mlton20180207
}:

{ l4vConfig
}:

let

in
self: with self; {

  inherit l4vConfig;

  wip = callPackage ./wip {};

  ### aggregate ###

  slow = writeText "slow" (toString ([
    kernel
    hol4
    l4vSpec
  ] ++ lib.optionals l4vConfig.bvSupport [
    binaryVerificationInputs
    graphRefineInputs
    graphRefine.justStackBounds
    graphRefine.coverage
    graphRefine.demo
  ]));

  slower = writeText "slower" (toString [
    slow
    cProofs
    l4vAll
  ]);

  slowest = writeText "slowest" (toString ([
    slower
  ] ++ lib.optionals l4vConfig.bvSupport [
    graphRefine.all
  ]));

  all = writeText "all" (toString [
    slowest
    minimalBinaryVerificationInputs
    cProofs
  ]);

  cachedForPrimary = writeText "cached" (toString [
    slow
    cProofs
    # l4vAll
  ]);

  cachedWhenBVSupport = writeText "cached" (toString [
    graphRefineInputs
  ]);

  cachedForAll = writeText "cached" (toString [
    kernel
    l4vSpec
    cProofs
  ]);

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

    currentGraphRefineNoSeL4 = lib.cleanSourceWith ({
      src = rawSources.currentGraphRefine;
      filter = path: type: builtins.match ".*/seL4-example/.*" path == null;
    });

    currentGraphRefineJustSeL4 = lib.cleanSourceWith ({
      src = rawSources.currentGraphRefine;
      filter = path: type: builtins.match ".*/seL4-example(/.*)?" path != null;
    });
  };

  sources = {
    inherit (rawSources)
      hol4
      graphRefine graphRefineNoSeL4 graphRefineJustSeL4
      currentGraphRefine currentGraphRefineNoSeL4 currentGraphRefineJustSeL4;
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

  minimalBinaryVerificationInputs = l4vWith {
    name = "minimal-bv-input";
    buildStandaloneCParser = l4vConfig.bvSupport;
    simplExport = l4vConfig.bvSupport;
  };

  standaloneCParser = assert l4vConfig.bvSupport; l4vWith {
    name = "standalone-cparser";
    buildStandaloneCParser = true;
  };

  simplExport = assert l4vConfig.bvSupport; l4vWith {
    name = "simpl-export";
    buildStandaloneCParser = true;
  };

  # binaryVerificationInputs = cProofs;
  binaryVerificationInputs = minimalBinaryVerificationInputs;

  hol4 = callPackage ./hol4.nix {};

  graphRefineInputs = callPackage ./graph-refine-inputs.nix {};

  minimalGraphRefineInputs =
    let
      files = [
        "kernel.elf.symtab"
        "kernel.elf.rodata"
        "CFunctions.txt"
        "ASMFunctions.txt"
        "target.py"
      ];
    in
      runCommand "minimal-graph-refine-inputs" {} ''
        cd ${graphRefineInputs}
        for config in *; do
          install -D -t $out/$config $config/{${lib.concatStringsSep "," files}}
        done
      '';

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

  currentGraphRefine = callPackage ./current-graph-refine.nix {};

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
}
