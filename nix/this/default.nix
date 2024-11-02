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
    , seL4Source ? kernelPairs.local.sources.seL4
    , l4vSource ? kernelPairs.local.sources.l4v
    , hol4Source ? localHol4Source
    , graphRefineSource ? gitignoreSource ../../projects/graph-refine
    , bvSandboxSource ? gitignoreSource ../../projects/bv-sandbox
    , seL4IsabelleSource ? defaultSeL4IsabelleSource
    , useSeL4Isabelle ? true
    , l4vName ? "${arch}${nameModification features}${nameModification plat}"
    , bvName ? "${l4vName}${optLevel}-${targetCC.name}"
    , bvSetupSupport ? lib.elem arch [ "ARM" "RISCV64" ] && !mcs && /* TODO */ !(arch == "RISCV64" && optLevel == "-O2")
    , bvSupport ? bvSetupSupport && lib.elem arch [ "ARM" ]
    , bvExclude ? ({
        "ARM-O1" = [ "init_freemem" ];
        "ARM-O2" = [ "init_freemem" "decodeARMMMUInvocation" ];
      }."${arch}${optLevel}" or null)
    }:
    {
      inherit
        arch mcs features plat
        optLevel
        targetCC targetBintools targetPrefix
        seL4Source
        l4vSource
        hol4Source
        graphRefineSource
        bvSandboxSource
        seL4IsabelleSource
        useSeL4Isabelle
        bvSetupSupport
        bvSupport
        bvExclude
        l4vName
        bvName
      ;
    };

  nameModification = tag: lib.optionalString (tag != "") "-${tag}";

  gitignore = callPackage ./gitignore.nix {};

  inherit (gitignore) gitignoreSource;

  localSeL4Source = gitignore.gitignoreSource ../../projects/seL4;
  localL4vSource = gitignore.gitignoreSource ../../projects/l4v;

  localHol4Source = lib.cleanSourceWith rec {
    src = ../../projects/HOL4;
    filter = gitignore.gitignoreFilterWith {
      basePath = src;
      extraRules = ''
        !/sigobj/*
      '';
    };
  };

  defaultSeL4IsabelleSource = builtins.fetchGit {
    url = "https://github.com/seL4/isabelle.git";
    # TODO
    # ref = "ts-2024";
    # rev = "e0dd5a6d89d2c0b37e7f1ffe0105050189136b75";
    ref = "Isabelle2024";
    rev = "74b2d1278b57797572abe5842e318d17ed131c55";
  };

  mkKeepRef = rev: "keep/${builtins.substring 0 32 rev}";

  fetchGitFromColiasGroup = { repo, rev }: builtins.fetchGit rec {
    url = "https://github.com/coliasgroup/${repo}.git";
    ref = mkKeepRef rev;
    inherit rev;
  };

  kernelPairs =
    let
      fetchPair = revs: mkPair (lib.flip lib.mapAttrs revs (repo: rev: fetchGitFromColiasGroup {
        inherit repo rev;
      }));
      mkPair = sources: {
        inherit sources;
        scopes = mkScopeTreeFromNamedConfigs (lib.forEach namedConfigs (config: config // {
          seL4Source = sources.seL4Source;
          l4vSource = sources.l4vSource;
        }));
      };
    in {
      local = mkPair {
        seL4 = gitignoreSource ../../projects/seL4;
        l4v = localL4vSource;
      };
      release = rec {
        upstream = {
          legacy = fetchPair {
            seL4 = "cd6d3b8c25d49be2b100b0608cf0613483a6fffa"; # seL4/seL4:13.0.0
            l4v = "f4054b0649446fb4ea03115f4b18160472964026"; # direct downstream of seL4/l4v:seL4-13.0.0
          };
        };
        downstream = {
          legacy = fetchPair {
            seL4 = "fef10c54376af898eaf26e38e2c79b2bf156ac40"; # coliasgroup:verification-reproducability
            l4v = throw "todo";
          };
        };
      };
      tip = rec {
        upstream = rec {
          legacy = fetchPair {
            seL4 = "caa2cd03ee2b48e44efc52a620b9a5a79df9de46"; # ancestor of u/master
            l4v = "6ec3e2c701bf066aac85eba67e894191e3fcacb7";
          };
          mcs = fetchPair {
            seL4 = legacy.seL4;
            l4v = "79039b0e26e6abd93e083d23b5e54a6a0cf2d494";
          };
        };
        downstream = rec {
          legacy = fetchPair {
            seL4 = throw "todo"; # direct downstream of upstream.legacy.seL4
            l4v = throw "todo";
          };
          mcs = fetchPair {
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
