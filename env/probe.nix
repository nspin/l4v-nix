{ lib
, writeText
, bash, coreutils, findutils
}:

let
  probe =
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
  inherit probe;
}
