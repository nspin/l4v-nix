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

  phases = [ "buildPhase" ];

  nativeBuildInputs = [
    isabelle
    hostname
    perl
  ];

  buildPhase = ''
    HOME=$out isabelle build -vb ${lib.concatStringsSep " " sessions}
  '';
}
