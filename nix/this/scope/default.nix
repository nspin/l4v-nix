{ lib
, pkgs
, pkgsStatic
, runCommand
, writeText
, linkFarm
, gcc9Stdenv
, texlive
, python3Packages
, python2
, polyml
, mlton
, mlton20180207
, mlton20210117
}:

self:

with self; {

  ### sources ###

  inherit (scopeConfig) hol4Source graphRefineSource bvSandboxSource;

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
    buildStandaloneCParser = scopeConfig.bvSetupSupport;
  };

  cProofs = l4vWith {
    name = "c-proofs";
    tests = [
      "CRefine"
    ] ++ lib.optionals scopeConfig.bvSetupSupport [
      "SimplExportAndRefine"
    ];
    buildStandaloneCParser = scopeConfig.bvSetupSupport;
  };

  justStandaloneCParser = l4vWith {
    name = "standalone-cparser";
    buildStandaloneCParser = true;
    excludeSeL4Source = true;
  };

  justSimplExport = l4vWith {
    name = "simpl-export";
    simplExport = scopeConfig.bvSetupSupport;
  };

  minimalBinaryVerificationInputs = l4vWith {
    name = "minimal-bv-input";
    buildStandaloneCParser = true;
    simplExport = scopeConfig.bvSetupSupport;
  };

  # binaryVerificationInputs = cProofs;
  # binaryVerificationInputs = minimalBinaryVerificationInputs;

  # standaloneCParser = binaryVerificationInputs;
  # simplExport = binaryVerificationInputs;

  standaloneCParser = justStandaloneCParser;
  simplExport = justSimplExport;

  hol4 = callPackage ./hol4.nix {};

  decompilation = callPackage ./decompilation.nix {};

  preprocessedKernelsAreEquivalent = callPackage ./preprocessed-kernels-are-equivalent.nix {};

  cFunctionsTxt = "${simplExport}/proof/asmrefine/export/${scopeConfig.arch}/CFunDump.txt";

  asmFunctionsTxt = "${decompilation}/kernel_mc_graph.txt";

  bvSandbox = callPackage ./bv-sandbox.nix {};

  graphRefineSolverLists = callPackage ./graph-refine-solver-lists.nix {};

  graphRefineWith = callPackage ./graph-refine.nix {};

  graphRefine = rec {

    defaultArgs = saveArgs ++ [
      "trace-to:report.txt"
    ];

    saveArgs = [
      "save:functions.txt"
      "save-pairings:pairings.txt"
      "save-inline-scripts:inline-scripts.txt"
      "save-problems:problems.txt"
      "save-proofs:proofs.txt"
    ];

    coverageArgs = [
      "trace-to:coverage.txt"
      "coverage"
    ];

    excludeArgs = lib.optionalAttrs (scopeConfig.bvExclude != null) ([
      "-exclude"
    ] ++ scopeConfig.bvExclude ++ [
      "-end-exclude"
    ]);

    justSave = graphRefineWith {
      name = "just-save";
      args = defaultArgs;
    };

    coverage = graphRefineWith {
      name = "coverage";
      args = excludeArgs ++ saveArgs ++ coverageArgs;
    };

    all = graphRefineWith {
      name = "all";
      argLists = [
        (excludeArgs ++ coverageArgs)
        (excludeArgs ++ defaultArgs ++ [
          "all"
        ])
      ];
    };

    demo = graphRefineWith {
      name = "demo";
      args = defaultArgs ++ [
        "deps:Kernel_C.cancelAllIPC"
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

  mltonForL4v = mlton20210117;

  ghcWithPackagesForL4v = callPackage  ./deps/ghc-with-packages-for-l4v {};

  mkIsabelleForL4v = callPackage ./deps/isabelle-for-l4v {};
  upstreamIsabelleForL4v = mkIsabelleForL4v false;
  seL4IsabelleForL4v = mkIsabelleForL4v true;

  isabelleForL4v = if scopeConfig.useSeL4Isabelle then seL4IsabelleForL4v else upstreamIsabelleForL4v;

  stdenvForHol4 = gcc9Stdenv;

  polymlForHol4 = lib.overrideDerivation polyml (attrs: {
    configureFlags = [ "--enable-shared" ];
  });

  mltonForHol4 = mlton20210117;

  sonolarBinary = callPackage ./deps/solvers-for-graph-refine/sonolar-binary.nix {};
  cvc4BinariesFromIsabelle = callPackage ./deps/solvers-for-graph-refine/cvc4-binaries-from-isabelle.nix {};
  cvc4Binaries = callPackage ./deps/solvers-for-graph-refine/cvc4-binaries.nix {};
  cvc5Binary = callPackage ./deps/solvers-for-graph-refine/cvc5-binary.nix {};
  mathsat5Binary = callPackage ./deps/solvers-for-graph-refine/mathsat5-binary.nix {};
  bitwuzla_0_2_0 = pkgsStatic.callPackage ./deps/solvers-for-graph-refine/bitwuzla-0.2.0.nix {
    pkgsDynamic = pkgs;
  };

  ### aggregate ###

  slow = writeText "slow" (toString ([
    kernel
    standaloneCParser
    simplExport
    l4vSpec
    hol4
  ] ++ lib.optionals scopeConfig.bvSetupSupport [
    decompilation
    preprocessedKernelsAreEquivalent
  ] ++ lib.optionals scopeConfig.bvSupport [
    graphRefine.justSave
    graphRefine.coverage
    graphRefine.demo
    sonolarModelBug.evidence
  ]));

  slower = writeText "slower" (toString ([
    slow
    # cProofs
    l4vAll
  ] ++ lib.optionals scopeConfig.bvSupport [
  ]));

  slowest = writeText "slowest" (toString ([
    slower
  ] ++ lib.optionals scopeConfig.bvSupport [
    graphRefine.all
  ]));

  excess = writeText "excess" (toString ([
    justStandaloneCParser
    justSimplExport
    minimalBinaryVerificationInputs
    cProofs
    sonolarDependence.evidence
  ]));

  all = writeText "all" (toString [
    slowest
    excess
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
    kernel
  ));

  ### helpers ###
  cppLink = linkFarm "cpp-link" {
    "bin/cpp" = "${scopeConfig.targetCC}/bin/${scopeConfig.targetPrefix}cpp";
  };

  l4vEnv = callPackage ./l4v-env.nix {};
  setupEnv = callPackage ./setup-env.nix {};

  containerXauthority = callPackage ./helpers/container-xauthority {};

  smtlib2-indent = python3Packages.callPackage ./helpers/smtlib2-indent {};

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
