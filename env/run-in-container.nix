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

    config = {
      User = "${uid}:${gid}";
      WorkingDir = "/build";
      Env = [
        "NIX_REMOTE=daemon"
        "NIX_BUILD_SHELL=bash"
        "NIX_SSL_CERT_FILE=/env/etc/ssl/certs/ca-bundle.crt"
        "HOME=/homless-shelter"
        "TMP=/tmp"
        "TMPDIR=/tmp"
        "TEMP=/tmp"
        "PATH=/env/bin"
      ];
    };
  };

  env = buildEnv {
    name = "env";
    paths = [
      nix
      cacert
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
        image=$(
          docker load < ${image} | sed -r 's/Loaded image: (.*)/\1/'
        )

        docker run --rm -it \
          ${passthru "/nix/store"} \
          ${passthru "/nix/var/nix/db"} \
          ${passthru "/nix/var/nix/daemon-socket"} \
          ${readonly sh "/bin/sh"} \
          ${readonly env "/env"} \
          "$image" \
          "$@"
      '';
  };

in {
  inherit image env run;
}

# NOTE
# export out=$(pwd)/out && (set -e && genericBuild)
