
{ lib
, haskell
}:

let
  haskellPackageSets = {
    "lts_13_15" = haskell.packages.ghc865Binary;
    "lts_19_12" = haskell.packages.ghc902;
    "lts_20_25" = haskell.packages.ghc928;
  };

in
lib.flip lib.mapAttrs haskellPackageSets (_: haskellPackages:
  (haskellPackages.override {
    overrides = self: super: {
      mtl = self.callPackage ./mtl_2_2_2.nix {};
    };
  }).ghcWithPackages (p: with p; [
    mtl
  ])
)
