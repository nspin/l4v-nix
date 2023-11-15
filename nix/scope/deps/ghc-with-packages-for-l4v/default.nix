
{ lib
, haskell
}:

let
  haskellPackages = haskell.packages.ghc865Binary.override {
    overrides = self: super: {
      mtl = self.callPackage ./mtl.nix {};
    };
  };

in
haskellPackages.ghcWithPackages (p: with p; [
  mtl
])
