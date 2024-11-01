{ lib
, stdenv
, isabelle
, scopeConfig
}:

isabelle.overrideAttrs (attrs:
  let
    origSrc = stdenv.mkDerivation {
      name = "isabelle-src";
      inherit (attrs) src;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        cp -r . $out
      '';
    };

  in {
    patches = (attrs.patches or []) ++ [
      ./permissions.patch
    ];
  } // lib.optionalAttrs (scopeConfig.isabelleSource != null) {
    name = "${attrs.name}-for-seL4";
    src = scopeConfig.isabelleSource;
    sourceRoot = null;
    postUnpack = ''
      oldSourceRoot=$sourceRoot
      sourceRoot=${attrs.dirname}
      mv $oldSourceRoot $sourceRoot
    '';
    prePatch = ''
      copy() {
        echo $1
        cp -r ${origSrc}/$1 $1
        chmod -R +w $1
      }
      copy contrib
      copy etc/components
      touch heaps
    '';
  }
)
