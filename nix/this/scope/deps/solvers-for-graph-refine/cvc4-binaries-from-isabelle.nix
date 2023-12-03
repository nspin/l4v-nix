{ lib, stdenv, hostPlatform, fetchurl }:

let
  mk = { version, hash }:
    stdenv.mkDerivation {
      pname = "cvc4-binary-from-isabelle";
      inherit version;
      src = fetchurl {
        url = "https://isabelle.sketis.net/components/cvc4-${version}.tar.gz";
        hash = "sha256-ozQ8QlWsLR9k+D1P66LtB22iPkKfFF2gBmqc1m6TIWI=";
      };
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        install -D -t $out/bin ${hostPlatform.system}/cvc4
      '';
    };
in {
  v1_5_3 = mk {
    version = "1.5-3";
    hash = "sha256-ozQ8QlWsLR9k+D1P66LtB22iPkKfFF2gBmqc1m6TIWI=";
  };
}
