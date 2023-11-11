env := $(shell nix-build -A env)

# printf "%s\n%s\n" "FROM scratch" "WORKDIR /"

.PHONY: nothing
nothing:

.PHONY: build
build:
	docker build -t minimal .

.PHONY: run
run: build
	docker run --rm \
		--mount type=bind,readonly,src=/nix/store,dst=/nix/store \
		--mount type=bind,readonly,src=/nix/var/nix/db,dst=/nix/var/nix/db \
		--mount type=bind,readonly,src=/nix/var/nix/daemon-socket,dst=/nix/var/nix/daemon-socket \
		-e NIX_REMOTE=daemon \
		-e NIX_BUILD_SHELL=bash \
		-e PATH=$(env)/bin \
		-e NIX_SSL_CERT_FILE=$(env)/etc/ssl/certs/ca-bundle.crt \
		-it minimal \
		$(env)/bin/bash
