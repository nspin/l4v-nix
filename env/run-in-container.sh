#!/usr/bin/env bash

set -eu

env=$(nix-build -A env)

image=$(
	docker build -q - << EOF
FROM scratch
WORKDIR /tmp
WORKDIR /x
EOF
)

passthru() {
	echo "--mount type=bind,readonly,src=$1,dst=$1"
}

docker run --rm -it \
	$(passthru /nix/store) \
	$(passthru /nix/var/nix/db) \
	$(passthru /nix/var/nix/daemon-socket) \
	-e NIX_REMOTE=daemon \
	-e NIX_BUILD_SHELL=bash \
	-e NIX_SSL_CERT_FILE=$env/etc/ssl/certs/ca-bundle.crt \
	-e PATH=$env/bin \
	$image \
	"$@"
