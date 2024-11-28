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
    , plat ? "" # TODO none should be null
    , optLevel ? null

    , targetCCWrapperAttr ? targetCCWrapperAttrForConfig { inherit arch bvSupport; }
    , targetCCWrapper ? targetPkgsByL4vArch."${arch}".buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetBintools ? targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix

    , localSeL4Source ? ../../projects/seL4
    , seL4Source ? gitignoreSource localSeL4Source
    , localL4vSource ? ../../projects/l4v
    , l4vSource ? cleanL4vSource localL4vSource
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
      }."${bvName}-${targetCC.name}" or (lib.warn "bvExclude not specified for ${bvName}" null))
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

  relevantOptLevels = {
    inherit (optLevels) o1 o2;
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

  nameModification = tag: lib.optionalString (tag != "") "_${tag}";

  gitignore = callPackage ./gitignore.nix {};

  inherit (gitignore) gitignoreSource;

  cleanL4vSource = src: lib.cleanSourceWith {
    inherit src;
    filter = gitignore.gitignoreFilterWith {
      basePath = src;
      extraRulesWithContextDir = [
        {
          # TODO this isn't working
          contextDir = src + "/spec/haskell";
          rules = ''
            !src/SEL4/Object/Structures.lhs-boot
          '';
        }
      ];
    };
  };

  cleanHol4Source = src: lib.cleanSourceWith {
    inherit src;
    filter = gitignore.gitignoreFilterWith {
      basePath = src;
      extraRules = ''
        !/sigobj/*
      '';
    };
  };

  defaultSeL4IsabelleSource = downstreamGitIsabelleSource;
  # defaultSeL4IsabelleSource = upstreamGitIsabelleSource;

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

  mkSourceAttrsFromRevs =
    { seL4 ? null
    , l4v ? null
    , hol4 ? null
    , graphRefine ? null
    , bvSandbox ? null
    , seL4Isabelle ? null
    } @ revs:
    lib.listToAttrs
      (lib.concatLists
        (lib.flip lib.mapAttrsToList revs (repo: rev:
          lib.optional
            (rev != null)
            (lib.nameValuePair "${repo}Source" (fetchGitFromColiasGroup {
              inherit repo rev;
            })))));

  channelSources = {
    release = {
      upstream = {
        legacy = mkSourceAttrsFromRevs {
          seL4 = "cd6d3b8c25d49be2b100b0608cf0613483a6fffa"; # seL4/seL4:13.0.0
          l4v = "205306814b6311b4781af1eb9534f674733a9735"; # direct downstream of seL4/l4v:seL4-13.0.0
        };
      };
      downstream = {
        legacy = mkSourceAttrsFromRevs {
          seL4 = "954b98b253abdbe14bcf6ffb41dcc24e52e51e9f"; # coliasgroup:verification-reproducability
          l4v = throw "todo";
        };
      };
    };
    tip = {
      upstream =
        let
        in {
          legacy = mkSourceAttrsFromRevs {
            seL4 = "c5b23791ea9f65efc4312c161dd173b7238c5e80"; # tracks u/master
            l4v = "3370365c879423236fb43338403224341204d575";
          };
          mcs = mkSourceAttrsFromRevs {
            seL4 = "5dd34db6298a476a57b89cf24176dd15e674eae5"; # behind u/master
            l4v = "e16ea558bedb1177c9ed9d65e4bde86f2e304687";
          };
        };
      downstream =
        let
        in {
          legacy = mkSourceAttrsFromRevs {
            seL4 = "e125c3b55385edca57bce14450e6ef661a3cf115"; # direct downstream of upstream.legacy.seL4
            l4v = "dd5c8f88a07ada43aa4f7b2bbd22cbef276f484d";
          };
          mcs = mkSourceAttrsFromRevs {
            seL4 = throw "todo";
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

      withRevs = revs: overrideConfig (mkSourceAttrsFromRevs revs);

      # HACK
      inherit fetchGitFromColiasGroup;
    });

  mkScopesWith = getName: configs: lib.listToAttrs (lib.forEach configs (config: rec {
    name = getName value.scopeConfig;
    value = mkScope config;
  }));

  mkL4vScopes = mkScopesWith (scopeConfig: scopeConfig.l4vName);

  mkBVScopes = mkScopesWith (scopeConfig: scopeConfig.bvName);

  namedConfigs =
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

  scopes = mkL4vScopes namedConfigs;

  scopesWithOptLevels =
    let
      configs = lib.flip lib.concatMap namedConfigs (config:
        lib.flip lib.concatMap (lib.attrValues relevantOptLevels) (optLevel:
          lib.singleton (config // {
            inherit optLevel;
          })
        )
      );
    in
      mkBVScopes configs;

  byChannel =
    lib.flip lib.mapAttrs channelSources (_:
      lib.mapAttrs (_:
        lib.mapAttrs (_: configAttrs:
          mkL4vScopes (lib.forEach namedConfigs (config: config // configAttrs))
        )
      )
    );

  defaultScope = scopes.ARM.o1;

  tests = writeText "aggregate-tests" (toString (lib.flatten [
    (lib.forEach (lib.attrValues scopesWithOptLevels) (scope: lib.optionals (scope.scopeConfig.plat == "") [
      (
        scope.slower
      )
    ]))
  ]));

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
        (mk all scopes.ARM.o1.withChannel.release.upstream)
        (mk all scopes.ARM.o2.withChannel.release.upstream)
        (mk justTargetDir scopes.RISCV64.o1.withChannel.release.upstream)
        (mk justTargetDir scopes.RISCV64.o2.withChannel.release.upstream)
      ];

  allConfigs = lib.flip lib.concatMap namedConfigs (config:
    lib.flip lib.concatMap (lib.attrValues optLevels) (optLevel:
      lib.flip lib.concatMap (lib.attrValues targetCCWrapperAttrs) (targetCCWrapperAttr:
        lib.singleton (config // {
          inherit optLevel targetCCWrapperAttr;
        })
      )
    )
  );

  all = writeText "aggregate-all" (toString (lib.flatten [
    displayStatus
    (lib.forEach (map mkScope allConfigs) (scope:
      scope.all
    ))
  ]));

}
