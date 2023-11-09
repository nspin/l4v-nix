{ lib
, runCommand, writeShellApplication, buildEnv
, dockerTools
, busybox-sandbox-shell
, nix, cacert
, busybox, bashInteractive
}:

let
  uid = "1000";
  gid = "100";

  etc = lib.mapAttrs builtins.toFile {
    passwd = ''
      root:x:0:0::/build:/noshell
      nixbld:x:${uid}:${gid}::/build:/noshell
      nobody:x:65534:65534::/:/noshell
    '';

    group = ''
      root:x:0:
      nixbld:!:${gid}:
      nogroup:x:65534:
    '';

    hosts = ''
      127.0.0.1 localhost
      ::1 localhost
    '';

    # HACK for convenience
    inputrc = ''
      set editing-mode vi
      set show-mode-in-prompt on
    '';
  };

  image = dockerTools.buildImage {
    name = "minimal";

    copyToRoot = runCommand "root" {} ''
      mkdir $out
      cd $out

      mkdir etc tmp build

      ${lib.concatStrings (lib.flip lib.mapAttrsToList etc (k: v: ''
        cp ${v} etc/${k}
      ''))}
    '';

    runAsRoot = ''
      chown nixbld:nixbld /build
      chmod 0700 /build
      chmod 0777 /tmp
    '';
  };

  env = buildEnv {
    name = "env";
    paths = [
      nix
      busybox
      bashInteractive
    ];
  };

  run = writeShellApplication {
    name = "run-in-container";
    text =
      let
        readonly = src: dst: "--mount type=bind,readonly,src=${src},dst=${dst}";
        passthru = path: readonly path path;
        sh = "${busybox-sandbox-shell}/bin/busybox";
      in ''
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

        if [ ''${#dockerArgs[@]} -eq 0 ]; then
          dockerArgs=(--rm -it)
        fi

        if [ ''${#cmd[@]} -eq 0 ]; then
          cmd=(bash)
        fi

        image=$(
          docker load < ${image} | sed -r 's/Loaded image: (.*)/\1/'
        )

        set -x

        exec docker run \
          --user ${uid}:${gid} \
          --workdir /build \
          ${passthru "/nix/store"} \
          ${passthru "/nix/var/nix/db"} \
          ${passthru "/nix/var/nix/daemon-socket"} \
          ${readonly sh "/bin/sh"} \
          -e NIX_REMOTE=daemon \
          -e NIX_BUILD_SHELL=bash \
          -e NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt \
          -e HOME=/homless-shelter \
          -e TMP=/tmp \
          -e TMPDIR=/tmp \
          -e TEMP=/tmp \
          -e PATH=${env}/bin \
          "''${dockerArgs[@]}" \
          "$image" \
          "''${cmd[@]}"
      '';
  };

in {
  inherit image env run;
}

# NOTE
# export out=$(pwd)/out && (set -e && genericBuild)
