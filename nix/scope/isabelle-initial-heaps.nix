{ lib, stdenv
, hostname, perl
, isabelle
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
    isabelle
    hostname
    perl
  ];

  buildCommand = ''
    export HOME=$(mktemp -d)

    isabelle build -bv ${lib.concatStringsSep " " sessions}

    mv $HOME/.isabelle $out
  '';
}
