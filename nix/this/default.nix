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
    , targetCCWrapperAttr ? targetCCWrapperAttrForArch arch
    , targetCCWrapper ? targetPkgsByL4vArch."${arch}".buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetBintools ? targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix
    , optLevel ? "-O1"
    , bvSupport ? lib.elem arch [ "ARM" "RISCV64" ]
    , seL4Source ? lib.cleanSource ../../projects/seL4
    , l4vSource ? lib.cleanSource ../../projects/l4v
    , hol4Source ? lib.cleanSource ../../projects/HOL4
    , graphRefineSource ? lib.cleanSource ../../projects/graph-refine
    , isabelleVersion ? "2023"
    , stackLTSAttr ? "lts_20_25"
    }:
    {
      inherit
        arch features plat
        targetCCWrapperAttr
        targetCC targetBintools targetPrefix
        optLevel
        bvSupport
        seL4Source
        l4vSource
        hol4Source
        graphRefineSource
        isabelleVersion
        stackLTSAttr
      ;
    };

  archs = {
    arm = "ARM";
    armHyp = "ARM_HYP";
    aarch64 = "AARCH64";
    riscv64 = "RISCV64";
    x64 = "X64";
  };

  targetCCWrapperAttrForArch = arch: if arch == "RISCV64" then "gcc12" else "gcc10";

  targetCCWrapperAttrs = lib.listToAttrs (map (v: lib.nameValuePair v v) [
    "gcc49" "gcc6" "gcc7" "gcc8" "gcc9" "gcc10" "gcc11" "gcc12" "gcc13"
  ]);

  optLevels = {
    o0 = "-O0";
    o1 = "-O1";
    o2 = "-O2";
  };

  targetPkgsByL4vArch = {
    "ARM" = armv7Pkgs;
    "ARM_HYP" = armv7Pkgs;
    "AARCH64" = aarch64Pkgs;
    "RISCV64" = riscv64Pkgs;
    "X64" = x64Pkgs;
  };

  armv7Pkgs = pkgsCross.arm-embedded;
  aarch64Pkgs = pkgsCross.aarch64-embedded;
  riscv64Pkgs = pkgsCross.riscv64-embedded;
  x64Pkgs = pkgs;

  # shorthand
  mk = scopeConfigArgs: mkScope {
    scopeConfig = lib.makeOverridable mkScopeConfig scopeConfigArgs;
  };

  named =
    let
      topLevel = rec {
        default = arm;

        arm = mk {
          arch = "ARM";
        };

        riscv64 = mk {
          arch = "RISCV64";
        };
      };
    in
      lib.fix (self: with self; topLevel // {

        o2 = lib.flip lib.mapAttrs topLevel (_: scope: scope.overrideScope (self: super: {
          scopeConfig = super.scopeConfig.override {
            optLevel = "-O2";
          };
        }));

        byConfig = lib.flip lib.mapAttrs archs (_: arch:
          lib.flip lib.mapAttrs targetCCWrapperAttrs (_: targetCCWrapperAttr:
            lib.flip lib.mapAttrs optLevels (_: optLevel:
              mkScope {
                scopeConfig = lib.makeOverridable mkScopeConfig {
                  inherit arch targetCCWrapperAttr optLevel;
                };
              }
            )
          )
        );
      });

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

  all = writeText "aggregate-all" (toString (mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = named.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in [
      scope.all
    ]
  )));

  cached = writeText "aggregate-cached" (toString ([
    named.default.cachedForPrimary
  ] ++ mkAggregate (
    { archName, targetCCWrapperAttrName, optLevelName }:
    let
      scope = named.byConfig.${archName}.${targetCCWrapperAttrName}.${optLevelName};
    in [
      scope.cachedForAll
    ] ++ lib.optionals scope.scopeConfig.bvSupport [
      scope.cachedWhenBVSupport
    ]
  )));
}
