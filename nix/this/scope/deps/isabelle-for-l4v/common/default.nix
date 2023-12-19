{ lib
, stdenv, hostPlatform
, runCommand, writeText
, linkFarm
, emptyDirectory
, fetchurl
, autoPatchelfHook
, openjdk17
, gmp
, vscodium

, isabelleSource
}:

let
  isabelleSource = lib.cleanSource ../../../../../../tmp/src/isabelle;

in

rec {
  componentExtension = self: super:
    let
      openjdk = openjdk17;
      jdkAttr = "jdk-17.0.7";
      jdkName = openjdk.name;
      vscodiumAttr = "vscodium-1.70.1";
      vscodiumName = vscodium.name;

      origVSCodiumComponent = super."${vscodiumAttr}".overrideAttrs (attrs: {
        dontAutoPatchelf = true;
      });

      getPatch = name: runCommand "${name}.patch" {} ''
        gunzip < ${origVSCodiumComponent}/patches/${name}.patch.gz > $out
      '';

      patchedVSCodium = vscodium.overrideAttrs (attrs: {
        patches = (attrs.patches or []) ++ [
          (getPatch "01-vscodium")
          (getPatch "02-isabelle_sources")
          (getPatch "03-isabelle_resources")
        ];
      });

      naprocheAttrs = lib.flip lib.mapAttrs (lib.filterAttrs (k: v: lib.hasPrefix "naproche" k) super) (k: v: v.overrideAttrs (attrs: {
        buildInputs = (attrs.buildInputs or []) ++ [
          gmp
        ];
      }));

    in naprocheAttrs // {

      "kodkodi-1.5.7" = super."kodkodi-1.5.7".overrideAttrs (attrs: {
        buildInputs = (attrs.buildInputs or []) ++ [
          "${openjdk}/lib/openjdk"
        ];
      });

      "${jdkAttr}" = mkLocalComponent {
        name = jdkName;
        settings = ''
          ISABELLE_JAVA_PLATFORM="$ISABELLE_PLATFORM64"
          ISABELLE_JDK_HOME=${openjdk}
        '';
      };

      # TODO
      "${vscodiumAttr}" = emptyDirectory;

      # "${vscodiumAttr}" = mkLocalComponent {
      #   name = vscodiumName;
      #   settings = ''
      #     ISABELLE_VSCODIUM_HOME="${patchedVSCodium}/lib/vscode"
      #     ISABELLE_VSCODIUM_ELECTRON="$ISABELLE_VSCODIUM_HOME/electron"
      #     ISABELLE_VSCODIUM_RESOURCES="$ISABELLE_VSCODIUM_HOME/resources"
      #   '';
      # };

      # "${vscodiumAttr}" = super."${vscodiumAttr}".overrideAttrs (attrs: {
      #   buildInputs = (attrs.buildInputs or []) ++ vscodium.buildInputs;
      #   # runtimeDependencies = (attrs.runtimeDependencies or []) ++ vscodium.runtimeDependencies;
      #   nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ vscodium.nativeBuildInputs;
      #   # dontAutoPatchelf = false;
      # });

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

  parseComponentListFile = contents:
    let
      lines = map lib.head (lib.filter lib.isList (builtins.split "([^\n]*)\n" contents));
      ignore = line: lib.stringLength line == 0 || lib.hasPrefix "#" line;
    in
      lib.filter (line: !(ignore line)) lines;

  fetchComponent = { name, sha1 }: fetchurl {
    url = "https://isabelle.in.tum.de/components/${name}.tar.gz";
    inherit sha1;
  };

  mkComponent = { name, src }: stdenv.mkDerivation (finalAttrs: {
    name = "isabelle-component-${name}";
    inherit src;
    dontAutoPatchelf = false;
    nativeBuildInputs = lib.optional (!finalAttrs.dontAutoPatchelf) [
      autoPatchelfHook
    ];
    buildInputs = [
      stdenv.cc.cc.lib
    ];
    phases = [ "unpackPhase" "patchPhase" "installPhase" "fixupPhase" ];
    installPhase = ''
      cp -r . $out
    '';
  });

  mkLocalComponent =
    { name, settings ? null, options ? null, components ? null, passthru ? {} }:
    runCommand "isabelle-local-component-${name}" {
      inherit passthru;
    } (''
      mkdir -p $out/etc
    '' + lib.optionalString (settings != null) ''
      ln -s ${writeText "settings" settings} $out/etc/settings
    '' + lib.optionalString (options != null) ''
      ln -s ${writeText "options" options} $out/etc/options
    '' + lib.optionalString (components != null) ''
      ln -s ${writeText "components" (lib.concatMapStrings (x: ''
        ${x}
      '') components)} $out/etc/components
    '');

  metaComponent = src:
    let
      componentHashes = parseHashesFile (lib.readFile (src + "/Admin/components/components.sha1"));
      allComponentsBeforeExtension =
        lib.flip lib.mapAttrs componentHashes (name: sha1: mkComponent {
          inherit name;
          src = fetchComponent {
            inherit name sha1;
          };
        });
      allComponents = lib.fix (lib.extends componentExtension (lib.const allComponentsBeforeExtension));
      platformSuffix =
        assert hostPlatform.isLinux;
        "linux${lib.optionalString hostPlatform.isAarch64 "_arm"}";
      componentListFnames = [
        "main"
        "bundled"
        "bundled-${platformSuffix}"
        "cakeml"
        "optional"
        "nonfree"
      ];
      componentList = lib.flip lib.concatMap componentListFnames
        (fname: parseComponentListFile (lib.readFile (src + "/Admin/components/${fname}")));
      components = map (componentName: allComponents.${componentName}) componentList;
    in
      mkLocalComponent {
        name = "meta";
        inherit components;
        passthru = {
          inherit allComponentsBeforeExtension allComponents;
        };
      };

    x = metaComponent isabelleSource;
}
