{ lib
, writeText
, texlive
, isabelle
}:

self: with self; {

  l4vConfig = {
    arch = "ARM";
    optLevel = "O1";
    targetPrefix = armv7Pkgs.stdenv.cc.targetPrefix;
    targetCC = armv7Pkgs.stdenv.cc;
  };

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

  armv7Pkgs = import ../../nixpkgs {
    crossSystem = {
      system = "armv7l-linux";
      config = "armv7l-unknown-linux-gnueabi";
    };
  };

  isabelle-sha1 = callPackage ./isabelle-sha1.nix {};

  isabelleInitialHeaps = callPackage ./isabelle-initial-heaps.nix {};

  hol4 = callPackage ./hol4.nix {};

  l4vSpecs = callPackage ./l4v-specs.nix {};

  l4vWith = callPackage ./l4v.nix {};

  l4vAllTests = l4vWith {
    testTargets = [
      "CRefine"
      "SimplExportAndRefine"
    ];
  };

  binaryVerificationInputs = l4vWith {
    # testTargets = [
    #   "CRefine"
    #   "SimplExportAndRefine"
    # ];
    buildStandaloneCParser = true;
    export = true;
  };

  graphRefineInputs = callPackage ./graph-refine-inputs.nix {};

  graphRefine = callPackage ./graph-refine.nix {};

  cached = writeText "cached" (toString [
    isabelle
    isabelleInitialHeaps
    binaryVerificationInputs
    hol4
    graphRefineInputs
    graphRefine
    l4vSpecs
  ]);

  all = writeText "all" (toString [
    cached
    l4vAllTests
  ]);
}
