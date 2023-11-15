#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

top_level := ../../..
cabal2nix := $(shell nix-build $(top_level) -A pkgs.cabal2nix --no-out-link)/bin/cabal2nix

all := capDL-tool.nix base-compat-0-11-2.nix base-compat-batteries-0-11-2.nix

.PHONY: all
all: $(all)

gen:
	mkdir -p $@

gen/base-compat-0-11-2.nix: | gen
	$(cabal2nix) cabal://base-compat-0.11.2 > $@

gen/base-compat-batteries-0-11-2.nix: | gen
	$(cabal2nix) cabal://base-compat-batteries-0.11.2 > $@
