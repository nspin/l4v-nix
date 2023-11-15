{ lib
, writeText
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

  oldNixpkgsSource = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "nixos-unstable";
    rev = "d4b654cb468790e7ef204ade22aed9b0d9632a7b";
  };

  oldNixpkgs = import oldNixpkgsSource {};

in
self: with self; {

  inherit oldNixpkgs;

  inherit l4vConfig;

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

  mlton = mlton20180207;

  polymlForHol4 = callPackage ./polyml-for-hol4.nix {
    libffi = libffi_3_3;
  };

  polymlForIsabelle = callPackage ./polyml-for-isabelle.nix {
    libffi = libffi_3_3;
  };

  z3ForIsabelle = callPackage ./z3-for-isabelle.nix {};

  hol4 = callPackage ./hol4.nix {
    polyml = polymlForHol4;
  };

  isabelle-sha1 = callPackage ./isabelle-sha1.nix {};

  isabelle = callPackage ./isabelle.nix {
    java = openjdk11;
    polyml = polymlForIsabelle;
    z3 = z3ForIsabelle;
    # z3 = z3_4_8_5;
    # z3 = oldNixpkgs.z3_4_4_0;
  };

  isabelleInitialHeaps = callPackage ./isabelle-initial-heaps.nix {};

  ghcWithPackagesForL4v = callPackage  ./ghc-with-packages-for-l4v {};

  l4vWith = callPackage ./l4v.nix {};

  l4vSpec = l4vWith {
    tests = [
      "ASpec"
    ];
  };

  l4vAll = l4vWith {
    tests = [];
    buildStandaloneCParser = bv;
  };

  cProofs = l4vWith {
    tests = [
      "CRefine"
    ] ++ lib.optionals bv [
      "SimplExportAndRefine"
    ];
    buildStandaloneCParser = bv;
  };

  minimalBinaryVerificationInputs = l4vWith {
    buildStandaloneCParser = true;
    simplExport = true;
  };

  # binaryVerificationInputs = cProofs;
  binaryVerificationInputs = minimalBinaryVerificationInputs;

  graphRefineInputs = callPackage ./graph-refine-inputs.nix {};

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefine = rec {
    justStackBounds = graphRefineWith {};
    coverage = graphRefineWith {
      targetDir = justStackBounds;
      commands = [
        [ "trace-to:coverage.txt" "coverage" ]
      ];
    };
    demo = graphRefineWith {
      targetDir = justStackBounds;
      commands = [
        [ "trace-to:report.txt" "deps:Kernel_C.cancelAllIPC" ]
      ];
    };
    all = graphRefineWith {
      targetDir = justStackBounds;
      commands = [
        [ "trace-to:report.txt" "all" ]
      ];
    };
  };

  cached = writeText "cached" (toString [
    isabelle
    isabelleInitialHeaps
    binaryVerificationInputs
    hol4
    graphRefineInputs
    graphRefine.justStackBounds
    graphRefine.coverage
    graphRefine.demo
    l4vSpec
  ]);

  all = writeText "all" (toString [
    cached
    l4vAll
    graphRefine.all
  ]);
}
