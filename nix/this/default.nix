{ lib
, callPackage, newScope
, pkgs, pkgsCross
, writeText
, linkFarm
}:

rec {

  mkScope = scopeConfigArgs: lib.makeScope newScope
    (self:
      ((callPackage ./scope {} self) // {
        scopeConfig = lib.makeOverridable mkScopeConfig scopeConfigArgs;
        overrideConfig = f: self.overrideScope (self: super: {
          scopeConfig = super.scopeConfig.override f;
        });
      } // mkScopeExtension {
        inherit (self) overrideConfig;
        superScopeConfig = self.scopeConfig;
      }));

  mkScopeConfig =
    { arch
    , mcs ? false
    , features ? lib.optionalString mcs "MCS"
    , plat ? ""
    , optLevel ? null

    , targetCCWrapperAttr ? targetCCWrapperAttrForConfig { inherit arch bvSupport; }
    , targetCCWrapper ? targetPkgsByL4vArch."${arch}".buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetBintools ? targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix

    , localSeL4Source ? ../../projects/seL4
    , seL4Source ? gitignoreSource localSeL4Source
    , localL4vSource ? ../../projects/l4v
    , l4vSource ? gitignore.gitignoreSource localL4vSource
    , localHol4Source ? ../../projects/HOL4
    , hol4Source ? cleanHol4Source localHol4Source
    , localGraphRefineSource ? ../../projects/graph-refine
    , graphRefineSource ? gitignoreSource localGraphRefineSource
    , localBVSandboxSource ? ../../projects/bv-sandbox
    , bvSandboxSource ? gitignoreSource localBVSandboxSource
    , seL4IsabelleSource ? defaultSeL4IsabelleSource
    , useSeL4Isabelle ? true

    , l4vName ? "${arch}${nameModification features}${nameModification plat}"
    , bvName ? "${l4vName}${optLevel}"

    , bvSetupSupport ? lib.elem arch [ "ARM" "RISCV64" ] && !mcs && /* TODO */ !(arch == "RISCV64" && optLevel == "-O2")
    , bvSupport ? bvSetupSupport && lib.elem arch [ "ARM" ]
    , bvExclude ? ({
        "ARM-O1-arm-none-eabi-gcc-6.5.0" = [ "init_freemem" ];
        "ARM-O2-arm-none-eabi-gcc-6.5.0" = [ "init_freemem" "decodeARMMMUInvocation" ];
      }."${bvName}" or (lib.warn "bvExclude not specified for ${bvName}" null))
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

  schedulerNameFromWhetherMCS = mcs: if mcs then "mcs" else "legacy";

  isMCSVerifiedForArch = lib.flip lib.hasAttr {
    arm = null;
    riscv64 = null;
  };

  verifiedSchedulersForArch = archName: [ "legacy" ] ++ lib.optional (isMCSVerifiedForArch archName) "mcs";

  platsForArchAndScheduler = { arch, mcs }: {
    AARCH64 = lib.optionals (!mcs) [
      "bcm2711"
      "hikey"
      "odroidc2"
      "odroidc4"
      "zynqmp"
    ];
    ARM = lib.optionals (!mcs) [
      "exynos4"
      "exynos5410"
      "exynos5422"
      "hikey"
      "tk1"
      "zynq7000"
      "zynqmp"
      "imx8mm"
    ];
    ARM_HYP = [
      "exynos5"
      "exynos5410"
    ];
  }.${arch} or [];

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

  # TODO "_"
  nameModification = tag: lib.optionalString (tag != "") "-${tag}";

  gitignore = callPackage ./gitignore.nix {};

  inherit (gitignore) gitignoreSource;

  cleanHol4Source = src: lib.cleanSourceWith {
    inherit src;
    filter = gitignore.gitignoreFilterWith {
      basePath = src;
      extraRules = ''
        !/sigobj/*
      '';
    };
  };

  # TODO
  # defaultSeL4IsabelleSource = downstreamGitIsabelleSource;
  defaultSeL4IsabelleSource = upstreamGitIsabelleSource;

  downstreamGitIsabelleSource = builtins.fetchGit {
    url = "https://github.com/seL4/isabelle.git";
    ref = "ts-2024";
    rev = "e0dd5a6d89d2c0b37e7f1ffe0105050189136b75";
  };

  upstreamGitIsabelleSource = builtins.fetchGit {
    url = "https://github.com/seL4/isabelle.git";
    ref = "Isabelle2024";
    rev = "74b2d1278b57797572abe5842e318d17ed131c55";
  };

  mkKeepRef = rev: "refs/tags/keep/${builtins.substring 0 32 rev}";

  fetchGitFromColiasGroup = { repo, rev }: builtins.fetchGit rec {
    url = "https://github.com/coliasgroup/${repo}.git";
    ref = mkKeepRef rev;
    inherit rev;
  };

  channelSources =
    let
      mkSources = revs:
        let
          fetched = lib.flip lib.mapAttrs revs (repo: rev: fetchGitFromColiasGroup {
            inherit repo rev;
          });
        in {
          seL4Source = fetched.seL4;
          l4vSource = fetched.l4v;
        };
    in {
      release = {
        upstream = {
          legacy = mkSources {
            seL4 = "cd6d3b8c25d49be2b100b0608cf0613483a6fffa"; # seL4/seL4:13.0.0
            l4v = "f4054b0649446fb4ea03115f4b18160472964026"; # direct downstream of seL4/l4v:seL4-13.0.0
          };
        };
        downstream = {
          legacy = mkSources {
            seL4 = "fef10c54376af898eaf26e38e2c79b2bf156ac40"; # coliasgroup:verification-reproducability
            l4v = throw "todo";
          };
        };
      };
      tip = {
        upstream =
          let
            seL4 = "caa2cd03ee2b48e44efc52a620b9a5a79df9de46"; # ancestor of u/master
          in {
            legacy = mkSources {
              inherit seL4;
              l4v = "6ec3e2c701bf066aac85eba67e894191e3fcacb7";
            };
            mcs = mkSources {
              inherit seL4;
              l4v = "79039b0e26e6abd93e083d23b5e54a6a0cf2d494";
            };
          };
        downstream =
          let
            seL4 = throw "todo"; # direct downstream of upstream.legacy.seL4
          in {
            legacy = mkSources {
              inherit seL4;
              l4v = throw "todo";
            };
            mcs = mkSources {
              inherit seL4;
              l4v = throw "todo";
            };
          };
      };
    };

  mkScopeExtension = { overrideConfig, superScopeConfig }:
    lib.fix (self: {
      withOptLevel = lib.flip lib.mapAttrs optLevels (_: optLevel:
        overrideConfig {
          inherit optLevel;
        }
      );

      inherit (self.withOptLevel) o0 o1 o2 o3;

      withGCC = lib.flip lib.mapAttrs targetCCWrapperAttrs (_: targetCCWrapperAttr:
        overrideConfig {
          inherit targetCCWrapperAttr;
        }
      );

      withSeL4Isabelle = overrideConfig {
        useSeL4Isabelle = true;
      };

      withoutSeL4Isabelle = overrideConfig {
        useSeL4Isabelle = false;
      };

      withChannel =
        let
          schedulerName = schedulerNameFromWhetherMCS superScopeConfig.mcs;
        in
          lib.flip lib.mapAttrs channelSources (_isRelease: isReleaseAttrs:
            lib.flip lib.mapAttrs isReleaseAttrs (_isUpstream: isUpstreamAttrs:
              overrideConfig (isUpstreamAttrs.${schedulerName})
            )
          );
    });

  namedConfigs' =
    lib.flip lib.concatMap (lib.attrNames archs) (archName:
      let
        arch = archs.${archName};
      in
      lib.flip lib.concatMap (verifiedSchedulersForArch archName) (schedulerName:
        let
          mcs = schedulers.${schedulerName};
        in
        lib.flip lib.concatMap (platsForArchAndScheduler { inherit arch mcs; } ++ [ "" ]) (plat:
          [
            {
              inherit arch mcs plat;
            }
          ]
        )
      )
    );

  namedScopes' = lib.listToAttrs (lib.forEach namedConfigs' (config: rec {
    name = value.scopeConfig.l4vName;
    value = mkScope config;
  }));
 
  x = namedScopes';

  # TODO
  # mkScopeTreeBy = argChoices: commonArgs:
  #   let
  #     x = lib.cartesianProduct (lib.mapAttrs (_: choices: lib.attrNames choices) argChoices);
  #     y = lib.forEach x (choices:
  #     );
  #   in
  # ;

  byChannel =
    lib.flip lib.mapAttrs channelSources (_isRelease: isReleaseAttrs:
      lib.flip lib.mapAttrs isReleaseAttrs (_isUpstream: isUpstreamAttrs:
        lib.flip lib.mapAttrs isUpstreamAttrs (_isLegacy: isLegacyAttrs:
          mkScopeTreeFromNamedConfigsWith (scope:
            scope.overrideConfig isLegacyAttrs
          ) namedConfigs
        )
      )
    );

  mkScopeFomNamedConfig =
    { archName, schedulerName, optLevelName, targetCCWrapperAttrName ? null } @ args:
    mkScope ({
      arch = archs.${archName};
      mcs = schedulers.${schedulerName};
      optLevel = optLevels.${optLevelName};
    } // lib.optionalAttrs (targetCCWrapperAttrName != null) {
      targetCCWrapperAttr = targetCCWrapperAttrs.${targetCCWrapperAttrName};
    });

  mkScopeTreeFromNamedConfigs = mkScopeTreeFromNamedConfigsWith lib.id;

  mkScopeTreeFromNamedConfigsWith = modifyScope:
    let
      f =
        { archName, schedulerName, optLevelName, targetCCWrapperAttrName ? null } @ args:
        lib.setAttrByPath
          ([ archName schedulerName optLevelName ] ++ lib.optionals (targetCCWrapperAttrName != null) [ targetCCWrapperAttrName ])
          (modifyScope (mkScopeFomNamedConfig args));
    in
      namedConfigs': lib.fold lib.recursiveUpdate {} (map f namedConfigs');

  scopes = mkScopeTreeFromNamedConfigs namedConfigs;

  allScopes = mkScopeTreeFromNamedConfigs allNamedConfigs;

  namedConfigs =
    lib.flip lib.concatMap (lib.attrNames archs) (archName:
      lib.flip lib.concatMap (lib.attrNames schedulers) (schedulerName:
        lib.flip lib.concatMap (lib.attrNames optLevels) (optLevelName:
          lib.optional
            (lib.elem optLevelName [ "o1" "o2" ] && (schedulerName == "legacy" || isMCSVerifiedForArch archName))
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
        name = scope.scopeConfig.bvName;
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
