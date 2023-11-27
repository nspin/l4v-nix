{ lib, stdenv
, hostname, perl
, isabelleForL4v
}:

let
  sessions = [
    "Pure"
    "HOL"
    "HOL-Word"
  ];

in
stdenv.mkDerivation {
  name = "isabelle-initial-heaps";

  nativeBuildInputs = [
    isabelleForL4v
    hostname
    perl
  ];

  buildCommand = ''
    export HOME=$(mktemp -d)

    isabelle build -bv ${lib.concatStringsSep " " sessions}

    mv $HOME/.isabelle $out
  '';
}
