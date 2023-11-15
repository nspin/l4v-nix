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
  this = mkThis {
    l4vConfig = mkL4vConfig {
      arch = "ARM";
    };
  };

  # WIP
  thisArmHyp = mkThis {
    l4vConfig = mkL4vConfig {
      arch = "ARM_HYP";
    };
  };

  # WIP
  thisX64 = mkThis {
    l4vConfig = mkL4vConfig {
      arch = "X64";
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

  isabelle = super.isabelle.overrideAttrs (attrs: {
    postPatch = attrs.postPatch + ''
      substituteInPlace \
        lib/Tools/env \
          --replace /usr/bin/env ${coreutils}/bin/env

      substituteInPlace \
        src/Pure/General/sha1.ML \
          --replace \
            '"$ML_HOME/" ^ (if ML_System.platform_is_windows then "sha1.dll" else "libsha1.so")' \
            '"${this.isabelle-sha1}/lib/libsha1.so"'
    '';
  });
}
