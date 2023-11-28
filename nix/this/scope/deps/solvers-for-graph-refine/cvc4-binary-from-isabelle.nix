{ lib, stdenv, hostPlatform, fetchurl }:

let
  mk = fetchurlArgs:
    stdenv.mkDerivation {
      name = "cvc4-binary-from-isabelle";
      src = fetchurl fetchurlArgs;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        install -D -t $out/bin ${hostPlatform.system}/cvc4
      '';
    };
in {
  v1_5_3 = mk {
    url = "https://isabelle.sketis.net/components/cvc4-1.5-3.tar.gz";
    hash = "sha256-ozQ8QlWsLR9k+D1P66LtB22iPkKfFF2gBmqc1m6TIWI=";
  };
}
