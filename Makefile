F ?= .
A ?= aggregate.cached

file := $(F)
attr := $(A)

cache_name := coliasgroup

.PHONY: default
default: all

.PHONY: all
all:
	nix-build -j1 -A aggregate.all --no-out-link

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build $(file) -j1 -A $(attr) --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)
