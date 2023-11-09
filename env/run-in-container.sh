#!/usr/bin/env bash

set -eu -o pipefail

here=$(dirname $0)

run=$(nix-build $here -A run --no-out-link)

exec $run/bin/run-in-container "$@"
