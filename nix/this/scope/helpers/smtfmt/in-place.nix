{ lib
, writeShellApplication
, smtfmt
}:

writeShellApplication rec {
  name = "smtfmt-in-place";

  runtimeInputs = [
    smtfmt
  ];

  text = ''
    contents=$(<"$1")
    smtfmt <<< "$contents" > "$1"
  '';
}
