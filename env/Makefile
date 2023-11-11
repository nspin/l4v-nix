env := $(shell nix-build -A env)

passthru = --mount  type=bind,readonly,src=$(1),dst=$(1)

.PHONY: default
default: run

.PHONY: build
build:
	docker build -t minimal .

.PHONY: run
run: build
	docker run --rm \
		$(call passthru,/nix/store) \
		$(call passthru,/nix/var/nix/db) \
		$(call passthru,/nix/var/nix/daemon-socket) \
		-e NIX_REMOTE=daemon \
		-e NIX_BUILD_SHELL=bash \
		-e NIX_SSL_CERT_FILE=$(env)/etc/ssl/certs/ca-bundle.crt \
		-e PATH=$(env)/bin \
		-it minimal \
		$(env)/bin/bash
