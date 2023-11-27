{ lib, runCommand, fetchurl }:

let
  mk = fetchurlArgs:
    let
      binary = fetchurl fetchurlArgs;
    in
    runCommand "cvc4-binary" {} ''
      install -D -T ${binary} $out/bin/cvc4
    '';
in {
  v1_5 = mk {
    url = "http://cvc4.cs.stanford.edu/downloads/builds/x86_64-linux-opt/cvc4-1.5-x86_64-linux-opt";
    hash = "sha256-BKlQP+6T0QMYTv4WjaYCdijdrj63NPb0tYQfGNPbzF4=";
  };
  v1_6 = mk {
    url = "http://cvc4.cs.stanford.edu/downloads/builds/x86_64-linux-opt/cvc4-1.6-x86_64-linux-opt";
    hash = "sha256-FdOt8lT+v57ixdKwbwHYDwLS4n0vh8lktUcNhZbwOBM=";
  };
  v1_8 = mk {
    url = "https://github.com/CVC4/CVC4/releases/download/1.8/cvc4-1.8-x86_64-linux-opt";
    hash = "sha256-04p5z5hFknhe2kHsiI2UyhB6wfEwWHQCOAQeKMhHLlE=";
  };
}
