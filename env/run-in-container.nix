{ lib
, runCommand, writeShellApplication, buildEnv
, dockerTools
, busybox-sandbox-shell
, nix, cacert
, busybox, bashInteractive
}:

# NOTE
# export out=$(pwd)/out && (set -e && genericBuild)

# TODO: investigate issue with substituteInPlace

let
  uid = "1000";
  gid = "100";

  etc = lib.mapAttrs builtins.toFile {
    passwd = ''
      root:!:0:0::/root:/bin/false
      nixbld:!:${uid}:${gid}::/home/nixbld:/bin/false
      nobody:!:65534:65534::/var/empty:/bin/false
    '';

    group = ''
      root:!:0:
      nixbld:!:${gid}:
      nogroup:!:65534:
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

      mkdir -p etc tmp build root home/nixbld

      ${lib.concatStrings (lib.flip lib.mapAttrsToList etc (k: v: ''
        cp ${v} etc/${k}
      ''))}
    '';

    runAsRoot = ''
      chown nixbld:nixbld /build /home/nixbld
      chmod 0700 /root /build /home/nixbld
      chmod 0777 /tmp
    '';

    config = {
      User = "${uid}:${gid}";
      WorkingDir = "/build";
    };
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
        env = "${coreutils}/bin/env";
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
          ${passthru "/nix/store"} \
          ${passthru "/nix/var/nix/db"} \
          ${passthru "/nix/var/nix/daemon-socket"} \
          ${readonly sh "/bin/sh"} \
          ${readonly env "/usr/bin/env"} \
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
