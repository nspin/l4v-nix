{ lib, stdenv, isabelle, hostname, perl }:

let
  sessions = [
    "Pure"
    "HOL"
    "HOL-Word"
  ];

in
stdenv.mkDerivation {
  name = "initial-heaps";

  nativeBuildInputs = [
    isabelle
    hostname
    perl
  ];

  buildCommand = ''
    echo $PATH
    false
    export HOME=$(mktemp -d)
    
    isabelle build -b ${lib.concatStringsSep " " sessions}

    mv $HOME/.isabelle $out
  '';
}
