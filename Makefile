A ?= aggregate.cached

attr_to_push := $(A)

cache_name := coliasgroup

.PHONY: default
default: all

.PHONY: all
all:
	nix-build -j1 -A aggregate.all --no-out-link

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build -j1 -A $(attr_to_push) --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)
