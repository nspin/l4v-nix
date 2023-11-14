{ lib
, writeText
, texlive
, isabelle
}:

{ l4vConfig
}:

self: with self; {

  inherit l4vConfig;

  rawSources = {
    seL4 = lib.cleanSource ../../projects/seL4;
    l4v = lib.cleanSource ../../projects/l4v;
    hol4 = lib.cleanSource ../../projects/HOL4;
    graph-refine = lib.cleanSource ../../projects/graph-refine;
  };

  sources = {
    inherit (rawSources) hol4 graph-refine;
    seL4 = callPackage ./sel4-source.nix {};
    l4v = callPackage ./l4v-source.nix {};
  };

  texliveEnv = with texlive; combine {
    inherit
      collection-fontsrecommended
      collection-latexextra
      collection-metapost
      collection-bibtexextra
      ulem
    ;
  };

  isabelle-sha1 = callPackage ./isabelle-sha1.nix {};

  isabelleInitialHeaps = callPackage ./isabelle-initial-heaps.nix {};

  hol4 = callPackage ./hol4.nix {};

  l4vWith = callPackage ./l4v.nix {};

  l4vSpec = l4vWith {
    testTargets = [
      "ASpec"
    ];
  };

  l4vAllTests = l4vWith {
    testTargets = [];
    buildStandaloneCParser = true;
  };

  fullBinaryVerificationInputs = l4vWith {
    testTargets = [
      "CRefine"
      "SimplExportAndRefine"
    ];
    buildStandaloneCParser = true;
  };

  minimalBinaryVerificationInputs = l4vWith {
    buildStandaloneCParser = true;
    simplExport = true;
  };

  binaryVerificationInputs = minimalBinaryVerificationInputs;

  graphRefineInputs = callPackage ./graph-refine-inputs.nix {};

  graphRefine = callPackage ./graph-refine.nix {};

  cached = writeText "cached" (toString [
    isabelle
    isabelleInitialHeaps
    binaryVerificationInputs
    hol4
    graphRefineInputs
    graphRefine
    l4vSpec
  ]);

  all = writeText "all" (toString [
    cached
    l4vAllTests
  ]);
}
