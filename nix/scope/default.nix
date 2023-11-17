{ lib
, writeText
, gcc49Stdenv
, gcc9Stdenv
, texlive
, mlton20180207
, libffi_3_3
, openjdk11
, z3_4_8_5
}:

{ l4vConfig
}:

let
  bv = l4vConfig.arch == "ARM";

in
self: with self; {

  inherit l4vConfig;


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
    l4vAll
  ]);

  slowest = writeText "slowest" (toString [
    slower
    graphRefine.all
  ]);

  cached = writeText "cached" (toString [
    slow
    cProofs
  ]);

  all = writeText "all" (toString [
    cached
    minimalBinaryVerificationInputs
    cProofs
    l4vAll
    graphRefine.all
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

  hol4 = callPackage ./hol4.nix {
    stdenv = gcc9Stdenv;
    polyml = polymlForHol4;
  };

  graphRefineInputs = callPackage ./graph-refine-inputs.nix {
    polyml = polymlForHol4;
  };

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefine = rec {
    justStackBounds = graphRefineWith {
      name = "just-stack-bounds";
    };
    coverage = graphRefineWith {
      name = "coverage";
      targetDir = justStackBounds;
      commands = [
        [ "trace-to:coverage.txt" "coverage" ]
      ];
    };
    demo = graphRefineWith {
      name = "demo";
      targetDir = justStackBounds;
      commands = [
        [ "trace-to:report.txt" "deps:Kernel_C.cancelAllIPC" ]
      ];
    };
    all = graphRefineWith {
      name = "all";
      targetDir = justStackBounds;
      commands = [
        [ "trace-to:report.txt" "all" ]
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

  mlton = mlton20180207;

  polymlForHol4 = callPackage ./deps/polyml-for-hol4.nix {
    libffi = libffi_3_3;
  };

  polymlForIsabelle = callPackage ./deps/polyml-for-isabelle.nix {
    libffi = libffi_3_3;
  };

  z3ForIsabelle = callPackage ./deps/z3-for-isabelle.nix {
    stdenv = gcc49Stdenv;
  };

  isabelle = callPackage ./deps/isabelle.nix {
    java = openjdk11;
    polyml = polymlForIsabelle;
    z3 = z3ForIsabelle;
    # z3 = z3_4_8_5;
  };

  isabelleInitialHeaps = callPackage ./isabelle-initial-heaps.nix {};

  sonolarBinary = callPackage ./deps/sonolar-binary.nix {};
  cvc4Binary = callPackage ./deps/cvc4-binary.nix {};
  cvc5Binary = callPackage ./deps/cvc5-binary.nix {};
}
