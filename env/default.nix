let
  nixpkgs = builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    ref = "nixos-unstable";
    rev = "85f1ba3e51676fa8cc604a3d863d729026a6b8eb";
  };

  pkgs = import nixpkgs {};

  inherit (pkgs) lib;

  etc = lib.mapAttrs builtins.toFile {
    passwd = ''
      root:x:0:0:Nix build user:/build:/noshell
      nixbld:x:1000:100:Nix build user:/build:/noshell
      nobody:x:65534:65534:Nobody:/:/noshell
    '';

    group = ''
      root:x:0:
      nixbld:!:100:
      nogroup:x:65534:
    '';

    hosts = ''
      127.0.0.1 localhost
      ::1 localhost
    '';
  };

  image = pkgs.dockerTools.buildImage {
    name = "minimal";

    copyToRoot = pkgs.runCommand "root" {} ''
      mkdir $out
      cd $out
      mkdir tmp build bin etc
      ln -s /env/bin/bash bin/sh
      ${lib.concatStrings (lib.flip lib.mapAttrsToList etc (k: v: ''
        cp ${v} etc/${k}
      ''))}
    '';

    config = {
      WorkingDir = "/build";
      Env = [
        "NIX_REMOTE=daemon"
        "NIX_BUILD_SHELL=bash"
        "NIX_SSL_CERT_FILE=/env/etc/ssl/certs/ca-bundle.crt"
        "HOME=/homless-shelter"
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
          "$image" \
          "$@"
      '';
  };

in {
  inherit image env run;
}
