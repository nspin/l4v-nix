cabal2nix := $(shell nix-build ../../.. -A pkgs.cabal2nix --no-out-link)/bin/cabal2nix

.PHONY: all
all: mtl.nix

mtl.nix:
	$(cabal2nix) cabal://mtl-2.2.2 > $@
