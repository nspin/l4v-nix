F ?= .
A ?= this.cached

file := $(F)
attr := $(A)

cache_name := coliasgroup

.PHONY: none
none:

.PHONY: eval-all
eval-all:
	nix-instantiate -A this.all

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build $(file) -j1 -A $(attr) --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)
