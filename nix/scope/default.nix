{ lib
, stdenv
, writeText
, texlive
, gcc9Stdenv
, mlton20180207
}:

{ l4vConfig
}:

let
  bv = l4vConfig.arch == "ARM";

in
self: with self; {

  inherit l4vConfig;

  wip = callPackage ./wip {};

  ### aggregate ###

  slow = writeText "slow" (toString [
    kernel
    hol4
    binaryVerificationInputs
    graphRefineInputs
    graphRefine.justStackBounds
    graphRefine.coverage
    graphRefine.demo
    l4vSpec
  ]);

  slower = writeText "slower" (toString [
    slow
    cProofs
    l4vAll
  ]);

  slowest = writeText "slowest" (toString [
    slower
    graphRefine.all
  ]);

  cached = writeText "cached" (toString [
    slow
    # cProofs
    # l4vAll
    # graphRefine.all
  ]);

  all = writeText "all" (toString [
    slowest
    minimalBinaryVerificationInputs
    cProofs
  ]);

  ### sources ###

  rawSources = {
    seL4 = lib.cleanSource ../../projects/seL4;
    l4v = lib.cleanSource ../../projects/l4v;
    hol4 = lib.cleanSource ../../projects/HOL4;
    graphRefine = lib.cleanSource ../../projects/graph-refine;
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
    inherit (rawSources) hol4 graphRefine graphRefineNoSeL4 graphRefineJustSeL4;
    seL4 = callPackage ./patched-sel4-source.nix {};
    l4v = callPackage ./patched-l4v-source.nix {};
  };

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
    buildStandaloneCParser = bv;
  };

  cProofs = l4vWith {
    name = "c-proofs";
    tests = [
      "CRefine"
    ] ++ lib.optionals bv [
      "SimplExportAndRefine"
    ];
    buildStandaloneCParser = bv;
  };

  minimalBinaryVerificationInputs = l4vWith {
    name = "minimal-bv-input";
    buildStandaloneCParser = true;
    simplExport = true;
  };

  # binaryVerificationInputs = cProofs;
  binaryVerificationInputs = minimalBinaryVerificationInputs;

  hol4 = callPackage ./hol4.nix {};

  graphRefineInputs = callPackage ./graph-refine-inputs.nix {};

  graphRefineSolverLists = callPackage ./graph-refine-solver-lists.nix {};

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefine = rec {
    justStackBounds = graphRefineWith {
      name = "just-stack-bounds";
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
        "trace-to:report.txt" "deps:Kernel_C.cancelAllIPC"
      ];
    };
    all = graphRefineWith {
      name = "all";
      targetDir = justStackBounds;
      args = [
        "trace-to:report.txt" "all"
      ];
    };
  };

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
  cvc4Binary = callPackage ./deps/solvers-for-graph-refine/cvc4-binary.nix {};
  cvc5Binary = callPackage ./deps/solvers-for-graph-refine/cvc5-binary.nix {};

  ### choices ###

  stdenvForHol4 = gcc9Stdenv;

  mlton = mlton20180207;

  polymlForHol4 = polyml58ForHol4;

  isabelleForL4v = isabelle2020ForL4v;
}
