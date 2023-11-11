{ lib
, texlive
}:

self: with self; {

  rawSources = {
    seL4 = lib.cleanSource ../projects/seL4;
    l4v = lib.cleanSource ../projects/l4v;
  };

  sources = {
    seL4 = callPackage ./sel4-source.nix {};
    l4v = callPackage ./l4v-source.nix {};
  };

  texlive-env = with texlive; combine {
    inherit
      collection-fontsrecommended
      collection-latexextra
      collection-metapost
      collection-bibtexextra
      ulem
    ;
  };

  armv7Pkgs = import ../nixpkgs {
    crossSystem = {
      system = "armv7l-linux";
      config = "armv7l-unknown-linux-gnueabi";
    };
  };

  isabelle-sha1 = callPackage ./isabelle-sha1.nix {};

  initial-heaps = callPackage ./initial-heaps.nix {};

  specs = callPackage ./specs.nix {};

  tests = callPackage ./tests.nix {
    # verbose = true;
    testTargets = [
      "CRefine"
      "SimplExportAndRefine"
    ];
  };

  all = [
    specs
    # tests
  ];
}
