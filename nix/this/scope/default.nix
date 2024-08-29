{ lib
, pkgs
, pkgsStatic
, runCommand
, writeText
, gcc9Stdenv
, texlive
, python2
, polyml
, mlton
, mlton20180207
, mlton20210107
}:

{ scopeConfig
}:

# scopeConfig gymnastics allow for overriding

let
  origScopeConifig = scopeConfig;
in

self:

let
  scopeConfig = self.scopeConfig;
in

with self; {

  scopeConfig = origScopeConifig;

  configName = "${scopeConfig.arch}${lib.optionalString (scopeConfig.features != "") "_${scopeConfig.features}"}${scopeConfig.optLevel}";

  ### sources ###

  inherit (scopeConfig) hol4Source graphRefineSource;

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
        "trace-to:report.txt" "save:functions.txt" "save-proofs:proofs.txt"
        "save-problems:problems.txt"
        "save-pairings:pairings.txt"
        "coverage"
        # "deps:Kernel_C.cancelAllIPC"
        # "deps:Kernel_C.decodeARMMMUInvocation"
        # "deps:Kernel_C.copyMRs"
        # "deps:Kernel_C.create_untypeds"
        # "deps:Kernel_C.init_freemem"
        # "verbose"
        # "deps:Kernel_C.activate_kernel_vspace"
      ];
    };

    all = graphRefineWith {
      name = "all";
      args = [
        "trace-to:report.txt" "save:functions.txt" "save-proofs:proofs.txt" "all"
      ];
    };

    # aggregate

    everythingAtOnce = graphRefineWith {
      name = "everything-at-once";
      dontDecorateCommands = true;
      argLists = [
        [ "trace-to:coverage.txt" "coverage" ]
        [ "trace-to:report.txt" "save:functions.txt" "save-proofs:proofs.txt" "all" ]
      ];
    };
  };

  ### notes ###

  sonolarModelBug = callPackage ./notes/sonolar-model-bug {};
  sonolarDependence = callPackage ./notes/sonolar-dependence {};

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

  polyml58ForHol4 = callPackage ./deps/polyml-5.8-for-hol4.nix {};

  polyml59ForHol4 = lib.overrideDerivation polyml (attrs: {
    configureFlags = [ "--enable-shared" ];
  });

  sonolarBinary = callPackage ./deps/solvers-for-graph-refine/sonolar-binary.nix {};
  cvc4BinariesFromIsabelle = callPackage ./deps/solvers-for-graph-refine/cvc4-binaries-from-isabelle.nix {};
  cvc4Binaries = callPackage ./deps/solvers-for-graph-refine/cvc4-binaries.nix {};
  cvc5Binary = callPackage ./deps/solvers-for-graph-refine/cvc5-binary.nix {};
  mathsat5Binary = callPackage ./deps/solvers-for-graph-refine/mathsat5-binary.nix {};
  bitwuzla_0_2_0 = pkgsStatic.callPackage ./deps/solvers-for-graph-refine/bitwuzla-0.2.0.nix {
    pkgsDynamic = pkgs;
  };

  ### choices ###

  stdenvForHol4 = gcc9Stdenv;

  # polymlForHol4 = polyml58ForHol4;
  # mltonForHol4 = mlton20180207;

  polymlForHol4 = polyml59ForHol4;
  mltonForHol4 = mlton20210107;

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
    sonolarModelBug.evidence
    sonolarDependence.evidence
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
    graphRefine.everythingAtOnce
  ]));

  all = writeText "all" (toString [
    slowest
  ]);

  # TODO
  cachedForPrimary = writeText "cached" (toString [
    # slow
    slower
  ]);

  # TODO
  cachedWhenBVSupport = writeText "cached" (toString [
  ]);

  # TODO
  cachedForAll = writeText "cached" (toString (
    # Fails only with X64-O1 (all GCC versions)
    lib.optionals (!(scopeConfig.arch == "X64" && scopeConfig.optLevel == "-O1")) [
      kernel
    ]
  ));

  ### wip ###

  wip = callPackage ./wip {};

  # TODO For use with GDB. Not working.
  python2WithDebuggingSymbols = python2.overrideAttrs (attrs: {
    configureFlags = attrs.configureFlags ++ [
      "--with-pydebug"
    ];
    postInstall = (attrs.postInstall or "") + ''
      # *strip* shebang from libpython gdb script - it should be dual-syntax and
      # interpretable by whatever python the gdb in question is using, which may
      # not even match the major version of this python. doing this after the
      # bytecode compilations for the same reason - we don't want bytecode generated.
      mkdir -p $out/share/gdb
      sed '/^#!/d' Tools/gdb/libpython.py > $out/share/gdb/libpython.py
    '';
    dontStrip = true;
  });
}
