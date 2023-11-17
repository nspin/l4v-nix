{ lib, runCommand, fetchurl }:

let
  binary = fetchurl {
    url = "https://github.com/cvc5/cvc5/releases/download/cvc5-1.0.8/cvc5-Linux";
    hash = "sha256-/nSjrnBGLXFYcZGMYnfIixChM1q1Xs+1OhD/WqUB0go=";
  };
in
runCommand "cvc5-binary" {} ''
  install -D -T ${binary} $out/bin/cvc5
''
