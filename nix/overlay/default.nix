self: super: with self;

let
  pythonOverrides = callPackage ./python-overrides.nix {};

  mkScope = args: lib.makeScope newScope (callPackage ../scope {} args);

  mkL4vConfig =
    let
      defaultCCWrapper = arch: targetPkgsByL4vArch."${arch}".buildPackages.gcc8;
    in
    { arch
    , optLevel ? "-O1"
    , targetCC ? (defaultCCWrapper arch).cc
    , targetBintools ? (defaultCCWrapper arch).bintools.bintools
    , targetPrefix ? (defaultCCWrapper arch).targetPrefix
    }:
    {
      inherit arch optLevel targetCC targetBintools targetPrefix;
    };

  targetPkgsByL4vArch = {
    "ARM" = armv7Pkgs;
    "ARM_HYP" = armv7Pkgs;
    "X64" = x64Pkgs;
  };

  armv7Pkgs = pkgsCross.arm-embedded;

  riscv64Pkgs = pkgsCross.riscv64-embedded;

  x64Pkgs = self;

in {
  this = rec {
    inherit armv7Pkgs x64Pkgs;

    default = armO1;

    armO0 = mkScope {
      l4vConfig = mkL4vConfig {
        arch = "ARM";
        optLevel = "-O0";
      };
    };

    armO1 = mkScope {
      l4vConfig = mkL4vConfig {
        arch = "ARM";
        optLevel = "-O1";
      };
    };

    armO2 = mkScope {
      l4vConfig = mkL4vConfig {
        arch = "ARM";
        optLevel = "-O2";
      };
    };

    armHyp = mkScope {
      l4vConfig = mkL4vConfig {
        arch = "ARM_HYP";
      };
    };

    x86 = mkScope {
      l4vConfig = mkL4vConfig {
        arch = "X64";
      };
    };
  };

  # Add Python packages needed by the seL4 ecosystem
  pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
    (callPackage ./python-overrides.nix {})
    (self: super: {
      psutilForPython2 = self.psutil.overridePythonAttrs {
        disabled = false;
        doCheck = false;
      };
    })
  ];
}
