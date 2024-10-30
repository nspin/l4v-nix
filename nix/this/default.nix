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
    , targetCCWrapperAttr ? targetCCWrapperAttrForConfig { inherit arch bvSupport; }
    , targetCCWrapper ? targetPkgsByL4vArch."${arch}".buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetBintools ? targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix
    , seL4Source ? kernelPairs.local.seL4
    , l4vSource ? kernelPairs.local.l4v
    , hol4Source ? lib.cleanSource ../../projects/HOL4
    , graphRefineSource ? lib.cleanSource ../../projects/graph-refine
    , bvSandboxSource ? lib.cleanSource ../../projects/bv-sandbox
    , isabelleSource ? seL4IsabelleSource
    , isabelleVersion ? "2024"
    , stackLTSAttr ? "lts_20_25"
    , bvSetupSupport ? lib.elem arch [ "ARM" "RISCV64" ] && !mcs && /* TODO */ !(arch == "RISCV64" && optLevel == "-O2")
    , bvSupport ? bvSetupSupport && lib.elem arch [ "ARM" ]
    , bvExclude ? {
        "ARM-O1" = [ "init_freemem" ];
        "ARM-O2" = [ "init_freemem" "decodeARMMMUInvocation" ];
      }."${arch}${optLevel}" or null
    , l4vName ? "${arch}${
        lib.optionalString (features != "") "-${features}"
      }${
        lib.optionalString (plat != "") "-${plat}"
      }"
    , bvName ? "${l4vName}${optLevel}-${targetCC.name}"
    }:
    {
      inherit
        arch features plat
        optLevel
        mcs
        targetCC targetBintools targetPrefix
        seL4Source
        l4vSource
        hol4Source
        graphRefineSource
        bvSandboxSource
        isabelleSource
        isabelleVersion
        stackLTSAttr
        bvSetupSupport
        bvSupport
        bvExclude
      ;
    };

  seL4IsabelleSource = builtins.fetchGit {
    url = "https://github.com/seL4/isabelle.git";
    ref = "ts-2024";
    rev = "e0dd5a6d89d2c0b37e7f1ffe0105050189136b75";
  };

  mkKeepRef = rev: "keep/${builtins.substring 0 32 rev}";

  fetchGitFromColiasGroup = { repo, rev }: builtins.fetchGit rec {
    url = "https://github.com/coliasgroup/${repo}.git";
    ref = mkKeepRef rev;
    inherit rev;
  };

  kernelPairs =
    let
      f = lib.mapAttrs (repo: rev: fetchGitFromColiasGroup {
        inherit repo rev;
      });
    in {
      local = {
        seL4Source = lib.cleanSource ../../projects/seL4;
        l4vSource = lib.cleanSource ../../projects/l4v;
      };
      release = rec {
        upstream = {
          legacy = f {
            seL4 = "cd6d3b8c25d49be2b100b0608cf0613483a6fffa"; # seL4/seL4:13.0.0
            l4v = "205306814b6311b4781af1eb9534f674733a9735"; # direct downstream of seL4/l4v:seL4-13.0.0
          };
        };
        downstream = {
          legacy = f {
            seL4 = "fef10c54376af898eaf26e38e2c79b2bf156ac40"; # coliasgroup:verification-reproducability
            l4v = throw "todo";
          };
        };
      };
      tip = rec {
        upstream = rec {
          legacy = f {
            seL4 = "c5b23791ea9f65efc4312c161dd173b7238c5e80"; # ancestor of u/master
            l4v = "4f0706ef42cb205f534462faf787b6b6a076888d";
          };
          mcs = f {
            seL4 = legacy.seL4;
            l4v = "a232dc70c3bc5222af89ca7791cfd68651a74610";
          };
        };
        downstream = rec {
          legacy = f {
            seL4 = "d0a377dcfa518f67e6818d82a8254cf7f75ad87a"; # direct downstream of upstream.legacy.seL4
            l4v = throw "todo";
          };
          mcs = f {
            seL4 = legacy.seL4;
            l4v = throw "todo";
          };
        };
      };
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

  targetCCWrapperAttrForConfig = { arch, bvSupport }: if bvSupport then "gcc6" else "gcc12";

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
    mkOverridableScopeFromConfigArgs ({
      arch = archs.${archName};
      mcs = schedulers.${schedulerName};
      optLevel = optLevels.${optLevelName};
    } // lib.optionalAttrs (args ? targetCCWrapperAttrName) {
      targetCCWrapperAttr = targetCCWrapperAttrs.${args.targetCCWrapperAttrName};
    });

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
          (
            if scope.scopeConfig.mcs || scope.scopeConfig.arch == "AARCH64" || scope.scopeConfig.arch == "X64"
            then scope.slow
            else scope.slower
          )
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
      all = scope: scope.graphRefine.all;
      justTargetDir = scope: scope.graphRefine.all.targetDir;
    in
      linkFarm "display-status" [
        (mk all scopes.arm.legacy.o1)
        (mk all scopes.arm.legacy.o2)
        (mk justTargetDir scopes.riscv64.legacy.o1)
        (mk justTargetDir scopes.riscv64.legacy.o2)
      ];
}
