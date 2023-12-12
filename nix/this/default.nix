{ lib
, callPackage, newScope
, pkgs, pkgsCross
, writeText
, linkFarm
}:

rec {

  mkScope = args: lib.makeScope newScope (callPackage ./scope {} args);

  mkScopeConfig =
    { arch
    , mcs ? false
    , features ? lib.optionalString mcs "MCS"
    , plat ? ""
    , optLevel ? "-O1"
    , targetCCWrapperAttr ? targetCCWrapperAttrForArch arch
    , targetCCWrapper ? targetPkgsByL4vArch."${arch}".buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetBintools ? targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix
    , seL4Source ? lib.cleanSource ../../projects/seL4
    , l4vSource ? lib.cleanSource ../../projects/l4v
    , hol4Source ? lib.cleanSource ../../projects/HOL4
    , graphRefineSource ? lib.cleanSource ../../projects/graph-refine
    , isabelleVersion ? "2023"
    , stackLTSAttr ? "lts_20_25"
    , bvSupport ? lib.elem arch [ "ARM" "RISCV64" ]
    }:
    {
      inherit
        arch features plat
        optLevel
        targetCC targetBintools targetPrefix
        seL4Source
        l4vSource
        hol4Source
        graphRefineSource
        isabelleVersion
        stackLTSAttr
        bvSupport
      ;
    };

  archs = {
    arm = "ARM";
    armHyp = "ARM_HYP";
    aarch64 = "AARCH64";
    riscv64 = "RISCV64";
    x64 = "X64";
  };

  schedulers = {
    legacy = false;
    mcs = true;
  };

  archSupportsVerifiedMCS = arch: lib.elem arch [ "ARM" "RISCV64" ];

  optLevels = {
    o0 = "-O0";
    o1 = "-O1";
    o2 = "-O2";
    o3 = "-O3";
  };

  targetCCWrapperAttrForArch = arch: if arch == "RISCV64" then "gcc12" else "gcc10";

  targetCCWrapperAttrs = lib.listToAttrs (map (v: lib.nameValuePair v v) [
    "gcc49" "gcc6" "gcc7" "gcc8" "gcc9" "gcc10" "gcc11" "gcc12" "gcc13"
  ]);

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

  mkOverridableScopeFromConfigArgs = scopeConfigArgs: mkScope {
    scopeConfig = lib.makeOverridable mkScopeConfig scopeConfigArgs;
  };

  mkScopeFomNamedConfig =
    { archName, schedulerName, optLevelName, ... } @ args:
    mkOverridableScopeFromConfigArgs {
      arch = archs.${archName};
      mcs = schedulers.${schedulerName};
      optLevel = optLevels.${optLevelName};
    } // lib.optionalAttrs (args ? targetCCWrapperAttrName) {
        targetCCWrapperAttr = targetCCWrapperAttrs.${args.targetCCWrapperAttrName};
    };

  mkScopeTreeFromNamedConfigs =
    let
      f =
        { archName, schedulerName, optLevelName, ... } @ args:
        lib.setAttrByPath
          ([ archName schedulerName optLevelName ] ++ lib.optionals (args ? targetCCWrapperAttrName) [ args.targetCCWrapperAttrName ])
          (mkScopeFomNamedConfig args);
    in
      namedConfigs': lib.fold lib.recursiveUpdate {} (map f namedConfigs');

  scopes = mkScopeTreeFromNamedConfigs namedConfigs;

  allScopes = mkScopeTreeFromNamedConfigs allNamedConfigs;

  namedConfigs =
    lib.flip lib.concatMap (lib.attrNames archs) (archName:
      lib.flip lib.concatMap (lib.attrNames schedulers) (schedulerName:
        lib.flip lib.concatMap (lib.attrNames optLevels) (optLevelName:
          lib.optional
            (lib.elem optLevelName [ "o1" "o2" ] && (schedulerName == "legacy" || archSupportsVerifiedMCS archs.${archName}))
            {
              inherit archName schedulerName optLevelName;
            }
        )
      )
    );

  allNamedConfigs =
    lib.flip lib.concatMap (lib.attrNames archs) (archName:
      lib.flip lib.concatMap (lib.attrNames schedulers) (schedulerName:
        lib.flip lib.concatMap (lib.attrNames optLevels) (optLevelName:
          lib.flip lib.concatMap (lib.attrNames targetCCWrapperAttrs) (targetCCWrapperAttrName:
            lib.singleton {
              inherit archName schedulerName optLevelName targetCCWrapperAttrName;
            }
          )
        )
      )
    );

  defaultScope = scopes.arm.legacy.o1;

  all = writeText "aggregate-all" (toString (lib.flatten [
    displayStatus
    (lib.forEach (map mkScopeFomNamedConfig namedConfigs) (scope:
      scope.all
    ))
  ]));

  tests = writeText "tests"
    (toString
      (lib.flatten
        (lib.forEach (map mkScopeFomNamedConfig namedConfigs) (scope: [
          scope.l4vAll
        ] ++ lib.optionals scope.scopeConfig.bvSupport [
          scope.graphRefine.everythingAtOnce.preTargetDir
        ] ++ lib.optionals (!(scope.scopeConfig.arch == "X64" && scope.scopeConfig.optLevel == "-O1")) [
          scope.kernel
        ]))
      )
    );

  cached = writeText "aggregate-cached" (toString (lib.flatten [
    # TODO
  ]));

  displayStatus =
    let
      mk = f: scope: {
        name = scope.configName;
        path = f scope;
      };
      everythingAtOnce = scope: scope.graphRefine.everythingAtOnce;
      preTargetDir = scope: scope.graphRefine.everythingAtOnce.preTargetDir;
    in
      linkFarm "display-status" [
        (mk everythingAtOnce scopes.arm.legacy.o1)
        (mk preTargetDir scopes.arm.legacy.o2)
        (mk preTargetDir scopes.riscv64.legacy.o1)
        (mk preTargetDir scopes.riscv64.legacy.o2)
      ];
}
