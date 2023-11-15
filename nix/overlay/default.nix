self: super: with self;

let
  pythonOverrides = callPackage ./python-overrides.nix {};

  mkThis = args: lib.makeScope newScope (callPackage ../scope {} args);

  targetPkgsByL4vArch = {
    "ARM" = armv7Pkgs;
    "ARM_HYP" = armv7Pkgs;
    "X64" = x64Pkgs;
  };

  mkL4vConfig = { arch, optLevel ? "-O1" }:
    let
      targetPkgs = targetPkgsByL4vArch."${arch}";
    in {
      inherit arch optLevel;
      targetPrefix = targetPkgs.stdenv.cc.targetPrefix;
      targetCC = targetPkgs.stdenv.cc;
    };

in {
  this = rec {
    default = arm;

    arm = mkThis {
      l4vConfig = mkL4vConfig {
        arch = "ARM";
      };
    };

    armHyp = mkThis {
      l4vConfig = mkL4vConfig {
        arch = "ARM_HYP";
      };
    };

    x86 = mkThis {
      l4vConfig = mkL4vConfig {
        arch = "X64";
      };
    };
  };

  armv7Pkgs = import ../../nixpkgs {
    crossSystem = {
      system = "armv7l-linux";
      config = "armv7l-unknown-linux-gnueabi";
    };
  };

  x64Pkgs = self;

  python2 = super.python2.override {
    packageOverrides = pythonOverrides;
  };

  python3 = super.python3.override {
    packageOverrides = pythonOverrides;
  };

  isabelleFromNixpkgs = super.isabelle;

  isabelle = throw "wrong isabelle";
}
