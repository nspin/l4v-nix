F ?= .
A ?= this.cached

file := $(F)
attr := $(A)

cache_name := coliasgroup

display := display

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(display)

.PHONY: eval-all
eval-all:
	nix-instantiate -A this.all

.PHONY: push
push:
	nix-store -qR --include-outputs $$(nix-store -qd $$(nix-build $(file) -j1 -A $(attr) --no-out-link)) \
		| grep -v '\.drv$$' \
		| cachix push $(cache_name)

$(display):
	mkdir -p $@

$(display)/status: | $(display)
	src=$$(nix-build -j1 -A this.displayStatus --no-out-link) && \
	dst=$@ && \
	rm -rf $$dst && \
	cp -rL --no-preserve=owner,mode $$src $$dst
