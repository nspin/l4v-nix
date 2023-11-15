self: super: with self;

let
  pythonOverrides = callPackage ./python-overrides.nix {};

  mkScope = args: lib.makeScope newScope (callPackage ../scope {} args);

  mkL4vConfig =
    { arch
    , optLevel ? "-O1"
    , targetCC ? targetPkgsByL4vArch."${arch}".stdenv.cc
    , targetPrefix ? targetCC.targetPrefix
    }:
    {
      inherit arch optLevel targetCC targetPrefix;
    };

  targetPkgsByL4vArch = {
    "ARM" = armv7Pkgs;
    "ARM_HYP" = armv7Pkgs;
    "X64" = x64Pkgs;
  };

  armv7Pkgs = import ../../nixpkgs {
    crossSystem = {
      system = "armv7l-linux";
      config = "armv7l-unknown-linux-gnueabi";
    };
  };

  x64Pkgs = self;

in {
  this = rec {
    inherit armv7Pkgs x64Pkgs;

    default = arm;

    arm = mkScope {
      l4vConfig = mkL4vConfig {
        arch = "ARM";
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

  python2 = super.python2.override {
    packageOverrides = pythonOverrides;
  };

  python3 = super.python3.override {
    packageOverrides = pythonOverrides;
  };

  isabelleFromNixpkgs = super.isabelle;

  isabelle = throw "wrong isabelle";
}
