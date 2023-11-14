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
    graphRefine = lib.cleanSource ../../projects/graph-refine;
    graphRefineNoSeL4 = lib.cleanSourceWith ({
      src = rawSources.graphRefine;
      filter = type: path: builtins.match ".*/seL4-example/.*" path == null;
    });
    graphRefineJustSeL4 = lib.cleanSourceWith ({
      src = rawSources.graphRefine;
      filter = type: path: path == toString rawSources.graphRefine || builtins.match "/seL4-example/" path != null;
    });
  };

  x = "${rawSources.graphRefineNoSeL4}";
  y = "${rawSources.graphRefineJustSeL4}";

  sources = {
    inherit (rawSources) hol4 graphRefine graphRefineNoSeL4 graphRefineJustSeL4;
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

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefineDemo = graphRefineWith {
    target = "deps:Kernel_C.cancelAllIPC";
  };

  graphRefine = graphRefineWith {
    target = "all";
  };

  cached = writeText "cached" (toString [
    isabelle
    isabelleInitialHeaps
    binaryVerificationInputs
    hol4
    graphRefineInputs
    graphRefineDemo
    l4vSpec
  ]);

  all = writeText "all" (toString [
    cached
    l4vAllTests
    graphRefine
  ]);
}
