env := $(shell nix-build -A env)

bind_mount_ro = --mount  type=bind,readonly,src=$(1),dst=$(1)

.PHONY: nothing
nothing:

.PHONY: build
build:
	docker build -t minimal .

.PHONY: run
run: build
	docker run --rm \
		$(call bind_mount_ro,/nix/store) \
		$(call bind_mount_ro,/nix/var/nix/db) \
		$(call bind_mount_ro,/nix/var/nix/daemon-socket) \
		-e NIX_REMOTE=daemon \
		-e NIX_BUILD_SHELL=bash \
		-e PATH=$(env)/bin \
		-e NIX_SSL_CERT_FILE=$(env)/etc/ssl/certs/ca-bundle.crt \
		-it minimal \
		$(env)/bin/bash
