{ lib
, runCommand
, buildPythonApplication
, fetchFromGitHub
, antlr4
, setuptools
, antlr4-python3-runtime
}:

# WIP

let
  # grammarRepo = fetchFromGitHub {
  #   owner = "antlr";
  #   repo = "grammars-v4";
  #   rev = "153e5792dbf6ef7b635667e07686ac6a81da610b";
  #   sha256 = "sha256-2O5nn1EeOzzDrg5lvEbaOimDb0Z+oU5/riO6hnDO+Bw=";
  # };

  # grammar = "${grammarRepo}/smtlibv2/SMTLIBv2.g4";

  grammarRepo = fetchFromGitHub {
    owner = "julianthome";
    repo = "smtlibv2-grammar";
    rev = "13f4f4cbe92bcc39fe3b425873a8616d58638059";
    sha256 = "sha256-93otHKD+S8+eC0FlZ7gVy2oIz6TIbPk58nbGwNu67og=";
  };

  grammar = "${grammarRepo}/src/main/resources/SMTLIBv2.g4";

  gen = runCommand "gen" {
    nativeBuildInputs = [
      antlr4
    ];
  } ''
    antlr -Dlanguage=Python3 -visitor -listener ${grammar} -o $out
  '';

in

buildPythonApplication rec {
  name = "smtlib2-indent";

  pyproject = true;

  src = lib.cleanSource ./src;

  nativeBuildInputs = [
    setuptools
    antlr4
  ];

  propagatedBuildInputs = [
    antlr4-python3-runtime
  ];

  postPatch = ''
    cp --no-preserve=mode,ownership ${gen}/* smtlib2_indent

    find .
  '';

  passthru = {
    inherit gen grammarRepo;
  };
}
