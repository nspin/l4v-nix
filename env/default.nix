let
  nixpkgs = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "nixos-unstable";
    rev = "85f1ba3e51676fa8cc604a3d863d729026a6b8eb";
  };

  pkgs = import nixpkgs {};

  inherit (pkgs) lib;

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

  image = pkgs.dockerTools.buildImage {
    name = "minimal";

    copyToRoot = pkgs.runCommand "root" {} ''
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

  env = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      nix
      cacert
      busybox
      bashInteractive
    ];
  };

  run = pkgs.writeShellApplication {
    name = "run-in-container";
    text =
      let
        sh = "${pkgs.busybox-sandbox-shell}/bin/busybox";
        ro = src: dst: "--mount type=bind,readonly,src=${src},dst=${dst}";
        passthru = path: ro path path;
      in ''
        image=$(
          docker load < ${image} | sed -r 's/Loaded image: (.*)/\1/'
        )

        docker run --rm -it \
          ${passthru "/nix/store"} \
          ${passthru "/nix/var/nix/db"} \
          ${passthru "/nix/var/nix/daemon-socket"} \
          ${ro env "/env"} \
          ${ro sh "/bin/sh"} \
          "$image" \
          "$@"
      '';
  };

  probe =
    with pkgs;
    let
      prune = [ "/proc" "/dev" "/nix/store" ];
      builderScript = writeText "builder.sh" ''
        exec > $out

        ${coreutils}/bin/ls -al /

        echo

        ${findutils}/bin/find / -print -a \( ${
          lib.concatMapStringsSep " -o " (path: "-path ${path}") prune
        } \) -prune
        
        echo

        for f in passwd group hosts; do
          p=/etc/$f
          echo "$p:"
          echo
          ${coreutils}/bin/cat $p
          echo
        done

        ${coreutils}/bin/env
      '';
    in derivation {
      name = "probe";
      system = builtins.currentSystem;
      builder = "${bash}/bin/bash";
      args = [ "-e" builderScript ];
    };

in {
  inherit image env run;
  inherit probe;
}

# NOTE
# export out=$(pwd)/out && (set -e && genericBuild)
