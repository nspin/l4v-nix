cache_name := coliasgroup

.PHONY: default
default: all

.PHONY: all
all:
	nix-build -j1 -A all --no-out-link

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build -j1 -A cached --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)
