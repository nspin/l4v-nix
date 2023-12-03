{ lib
, callPackage, newScope
, pkgs, pkgsCross
, writeText
}:

rec {

  mkScope = args: lib.makeScope newScope (callPackage ./scope {} args);

  mkScopeConfig =
    { arch
    , features ? ""
    , plat ? ""
    , targetCCWrapperAttr ? "gcc8"
    , targetCCWrapper ? targetPkgsByL4vArch."${arch}".buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetBintools ? targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix
    , optLevel ? "-O1"
    , bvSupport ? arch == "ARM"
    , seL4Source ? lib.cleanSource ../../projects/seL4
    , l4vSource ? lib.cleanSource ../../projects/l4v
    , isabelleVersion ? "2023"
    , stackLTSAttr ? "lts_20_25"
    }:
    {
      inherit
        arch features plat
        targetCC targetBintools targetPrefix
        optLevel
        bvSupport
        seL4Source
        l4vSource
        isabelleVersion
        stackLTSAttr
      ;
    };

  archs = {
    arm = "ARM";
    armHyp = "ARM_HYP";
    x64 = "X64";
  };

  targetCCWrapperAttrs = lib.listToAttrs (map (v: lib.nameValuePair v v) [
    "gcc49" "gcc6" "gcc8" "gcc10"
  ]);

  optLevels = {
    o0 = "-O0";
    o1 = "-O1";
    o2 = "-O2";
  };

  targetPkgsByL4vArch = {
    "ARM" = armv7Pkgs;
    "ARM_HYP" = armv7Pkgs;
    "X64" = x64Pkgs;
  };

  armv7Pkgs = pkgsCross.arm-embedded;

  riscv64Pkgs = pkgsCross.riscv64-embedded;

  x64Pkgs = pkgs;

  mkAggregate = f:
    lib.flip lib.concatMap (lib.attrNames archs) (archName:
      lib.flip lib.concatMap (lib.attrNames targetCCWrapperAttrs) (targetCCWrapperAttrName:
        lib.flip lib.concatMap (lib.attrNames optLevels) (optLevelName:
          f {
            inherit archName targetCCWrapperAttrName optLevelName;
          }
        )
      )
    );

  primary = byConfig.arm.gcc10.o1;

  byConfig = lib.flip lib.mapAttrs archs (_: arch:
    lib.flip lib.mapAttrs targetCCWrapperAttrs (_: targetCCWrapperAttr:
      lib.flip lib.mapAttrs optLevels (_: optLevel:
        mkScope {
          scopeConfig = mkScopeConfig {
            inherit arch targetCCWrapperAttr optLevel;
          };
        }
      )
    )
  );

  all = writeText "aggregate-all" (toString (mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in [
      scope.all
    ]
  )));

  cached = writeText "aggregate-cached" (toString ([
    primary.cachedForPrimary
  ] ++ mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in [
      scope.cachedForAll
    ] ++ lib.optionals scope.scopeConfig.bvSupport [
      scope.cachedWhenBVSupport
    ]
  )));
}
