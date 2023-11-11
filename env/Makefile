env := $(shell nix-build -A env)

mount_bind_ro = --mount  type=bind,readonly,src=$(1),dst=$(1)

.PHONY: nothing
nothing:

.PHONY: build
build:
	docker build -t minimal .

.PHONY: run
run: build
	docker run --rm \
		$(call mount_bind_ro,/nix/store) \
		$(call mount_bind_ro,/nix/var/nix/db) \
		$(call mount_bind_ro,/nix/var/nix/daemon-socket) \
		-e NIX_REMOTE=daemon \
		-e NIX_BUILD_SHELL=bash \
		-e NIX_SSL_CERT_FILE=$(env)/etc/ssl/certs/ca-bundle.crt \
		-e PATH=$(env)/bin \
		-it minimal \
		$(env)/bin/bash
