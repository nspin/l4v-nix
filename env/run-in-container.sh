#!/usr/bin/env bash

set -eu -o pipefail

here=$(dirname $0)

env=$(nix-build $here -A env --no-out-link)

image=$(
	docker load < $(nix-build $here -A image --no-out-link) \
		| sed -r 's/Loaded image: (.*)/\1/'
)

passthru() {
	echo "--mount type=bind,readonly,src=$1,dst=$1"
}

docker run --rm -it \
	$(passthru /nix/store) \
	$(passthru /nix/var/nix/db) \
	$(passthru /nix/var/nix/daemon-socket) \
	--mount type=bind,readonly,src=$env,dst=/env \
	$image \
	"$@"
