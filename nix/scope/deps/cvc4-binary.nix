{ lib, runCommand, fetchurl }:

let
  binary = fetchurl {
    url = "http://cvc4.cs.stanford.edu/downloads/builds/x86_64-linux-opt/cvc4-1.5-x86_64-linux-opt";
    hash = "sha256-BKlQP+6T0QMYTv4WjaYCdijdrj63NPb0tYQfGNPbzF4=";
    # url = "http://cvc4.cs.stanford.edu/downloads/builds/x86_64-linux-opt/cvc4-1.6-x86_64-linux-opt";
    # hash = "sha256-FdOt8lT+v57ixdKwbwHYDwLS4n0vh8lktUcNhZbwOBM=";
    # url = "https://github.com/CVC4/CVC4/releases/download/1.8/cvc4-1.8-x86_64-linux-opt";
    # hash = "sha256-04p5z5hFknhe2kHsiI2UyhB6wfEwWHQCOAQeKMhHLlE=";
  };
in
runCommand "cvc4-binary" {} ''
  install -D -T ${binary} $out/bin/cvc4
''
