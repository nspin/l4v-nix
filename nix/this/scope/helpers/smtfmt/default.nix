{ lib
, writeShellApplication
, fetchFromGitHub
, python3
}:

let

  src = fetchFromGitHub {
    owner = "symflower";
    repo = "smtfmt";
    rev = "3ec6a3def17d6ef2baf42a648b76041e9e9e7636";
    sha256 = "sha256-3vUcuLfxrpESNcyEqjTuoNnQ8m52PAKpwJxJx/QawWU=";
  };

in

writeShellApplication rec {
  name = "smtfmt";

  runtimeInputs = [
    python3
  ];

  text = ''
    python3 ${src}/smtfmt.py "$@"
  '';
}
