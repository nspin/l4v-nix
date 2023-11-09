self: super: with self;

let

  pythonOverrides = callPackage ./python-overrides.nix {};

in {
  this = lib.makeScope newScope (callPackage ../scope {});

  python2 = super.python2.override {
    packageOverrides = pythonOverrides;
  };

  python3 = super.python3.override {
    packageOverrides = pythonOverrides;
  };

  isabelle = super.isabelle.overrideAttrs (attrs: {
    postPatch = attrs.postPatch + ''
      substituteInPlace lib/Tools/env \
        --replace /usr/bin/env ${coreutils}/bin/env

      substituteInPlace src/Pure/General/sha1.ML \
        --replace '"$ML_HOME/" ^ (if ML_System.platform_is_windows then "sha1.dll" else "libsha1.so")' '"${this.isabelle-sha1}/lib/libsha1.so"'
    '';
  });
}
