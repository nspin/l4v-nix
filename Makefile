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

show-coverage-diff: $(display)/status
	diff \
		<(grep -e '^Skipping' -e '^Aborting' docker-archaeology/release-12.0.0/target-sample/target/ARM-O1/coverage.txt | sort) \
		<(grep -e '^Skipping' -e '^Aborting' $(display)/status/ARM-O1/coverage.txt | sort) \
	|| true
