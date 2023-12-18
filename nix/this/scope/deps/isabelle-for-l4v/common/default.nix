{ lib
, stdenv
, fetchurl
, autoPatchelfHook

, isabelleSource
}:

let
  isabelleSource = lib.cleanSource ../../../../../../tmp/src/isabelle;
in

rec {
  x = fetchurl {
    url = "https://isabelle.in.tum.de/components/cakeml-2.0.tar.gz";
    sha1 = "f92cff635dfba5d4d77f469307369226c868542c";
  };

  parseHashesFile = contents:
    let
      pairs = lib.filter lib.isList (builtins.split "([^ ]*) ([^\n]*)\n" contents);
      f = pair:
        let
          hash = lib.elemAt pair 0;
          fname = lib.elemAt pair 1;
          m = builtins.match "(.*)\\.tar\\.gz" fname;
          name = assert m != null; lib.elemAt m 0;
        in
          lib.nameValuePair name hash;
    in
      lib.listToAttrs (map f pairs);

  fetchComponent = { name, sha1 }: fetchurl {
    url = "https://isabelle.in.tum.de/components/${name}.tar.gz";
    inherit sha1;
  };

  mkComponent = { name, src }: stdenv.mkDerivation {
    name = "isabelle-component-${name}";
    inherit src;
    nativeBuildInputs = [
      autoPatchelfHook
    ];
    buildInputs = [
      stdenv.cc.cc.lib
    ];
    phases = [ "unpackPhase" "patchPhase" "installPhase" "fixupPhase" ];
    installPhase = ''
      cp -r . $out
    '';
  };

  z =
    let
      path = isabelleSource + "/Admin/components/components.sha1";
      contents = lib.readFile path;
      hashes = parseHashesFile contents;
    in
      lib.flip lib.mapAttrs hashes (name: sha1: mkComponent {
        inherit name;
        src = fetchComponent {
          inherit name sha1;
        };
      });

  y = isabelleSource;
}
