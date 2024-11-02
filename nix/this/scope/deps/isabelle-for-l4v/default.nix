{ lib
, stdenv
, hostPlatform
, writeText
, runCommand
, fetchurl
, isabelle

, scopeConfig
, mltonForL4v
}:

useSeL4IsabelleSource:

let
  inherit (scopeConfig) seL4IsabelleSource;

  unpackedUpstreamSrc = stdenv.mkDerivation {
    name = "isabelle-src";
    inherit (isabelle) src;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      cp -r . $out
    '';
  };

  fetchComponent = name: sha1:
    let
      tarball = fetchurl {
        url = "https://isabelle.sketis.net/components/${name}.tar.gz";
        inherit sha1;
      };
    in
      runCommand "isabelle-component-${name}" {} ''
        tar -xzf ${tarball}
        mv ${name} $out
        for arch in ${lib.concatStringsSep " " otherArches}; do
          rm -rf $out/$arch
        done
      '';

  hashesSrc = seL4IsabelleSource + "/Admin/components/components.sha1";

  hashes = parseHashes (builtins.readFile hashesSrc);

  parseLinesWithComments = s:
    let
      lines = lib.splitString "\n" s;
      filterdLines = lib.filter (line: line != "" && !(lib.hasPrefix "#" line)) lines;
    in
      filterdLines;

  parseHashes = s:
    lib.listToAttrs (lib.forEach (parseLinesWithComments s) (line:
      let
        parts = builtins.match "([0-9a-f]{40}) (.*)\\.tar.gz" line;
      in
        lib.nameValuePair (lib.elemAt parts 1) (lib.elemAt parts 0)
    ));

  parseComponentList = s: parseLinesWithComments s;

  fetchComponents = componentList:
    lib.forEach componentList (componentName:
      lib.nameValuePair componentName (fetchComponent componentName hashes.${componentName}));

  componentListNames = [
    "bundled"
    "bundled-linux"
    "bundled-linux_arm"
    "bundled-macos"
    "bundled-windows"
    "cakeml"
    "ci-extras"
    "main"
    "nonfree"
    "optional"
    "windows"
  ];

  componentLists = lib.listToAttrs
    (lib.forEach componentListNames (fname:
      lib.nameValuePair
      fname
      (fetchComponents (parseComponentList (builtins.readFile (seL4IsabelleSource + "/Admin/components/${fname}"))))));

  bundle = with componentLists; main ++ bundled;

  bundleList = writeText "x" ''
    #bundled components
    ${lib.concatMapStringsSep "\n" ({ name, ... }: "contrib/${name}") bundle}
  '';

  allArches = [
    "x86_64-linux"
    "x86-linux"
    "arm64-linux"
    "arm64_32-linux"
    "x86_64-darwin"
    "x86_64_32-darwin"
    "arm64-darwin"
    "arm64_32-darwin"
    "x86_64-windows"
    "x86_64_32-windows"
    "x86-windows"
    "x86_64-cygwin"
    "x86-cygwin"
  ];

  thisArch = hostPlatform.system;

  otherArches =
    assert lib.elem thisArch allArches;
    lib.filter (arch: arch != thisArch) allArches;

  preparedSeL4Src = stdenv.mkDerivation {
    name = "sel4-isabelle-src";
    src = seL4IsabelleSource;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      rm -r Admin
      cat ${bundleList} >> etc/components
      mkdir contrib
      ${lib.concatStrings (lib.forEach bundle ({ name, value }: ''
        cp -r ${value} contrib/${name}
      ''))}
      cp -r . $out
    '';
  };

  diff = runCommand "x" {} ''
    diff -rq ${unpackedUpstreamSrc} ${preparedSeL4Src}
  '';
in

lib.extendDerivation true {
  mlton = mltonForL4v;
  inherit unpackedUpstreamSrc;
  inherit preparedSeL4Src;
  inherit diff;
} (isabelle.overrideAttrs (attrs: {
  patches = (attrs.patches or []) ++ [
    ./permissions.patch
  ];
} // lib.optionalAttrs useSeL4IsabelleSource {
  name = "${attrs.pname}-${attrs.version}-for-seL4";
  src = preparedSeL4Src;
  sourceRoot = null;
  postUnpack = ''
    oldSourceRoot=$sourceRoot
    sourceRoot=${attrs.dirname}
    mv $oldSourceRoot $sourceRoot
  '';
  prePatch = (attrs.postPath or "") + ''
    touch heaps
  '';
}))
