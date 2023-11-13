set -eu

dockerArgs=()
cmd=()

for arg in "$@"; do
    shift
    case "$arg" in
        --)
            cmd=("$@")
            break
            ;;
        *)
            dockerArgs+=("$arg")
            ;;
    esac
done
