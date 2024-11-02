{ lib
, mkShell
, makeFontsConf
, python3Packages
, cmake, ninja, dtc, libxml2
, perl
, which
, rsync
, stack

, strace

, xdg-utils
, firefox
, cacert

, git

, scopeConfig
, isabelleForL4v
, mltonForL4v
, texliveEnv
, cppLink
}:

mkShell {
  name = "l4v-env";

  nativeBuildInputs = [
    cmake ninja dtc libxml2
    perl
    which
    rsync
    stack

    python3Packages.sel4-deps

    scopeConfig.targetCC
    scopeConfig.targetBintools

    mltonForL4v

    texliveEnv
    cppLink

    strace

    xdg-utils
    firefox
    cacert

    git
  ];

  L4V_ARCH = scopeConfig.arch;
  L4V_FEATURES = scopeConfig.features;
  L4V_PLAT = scopeConfig.plat;
  L4V_NAME = scopeConfig.l4vName;
  TOOLPREFIX = scopeConfig.targetPrefix;

  # TODO
  # What does this do?
  # Is it appropriate?
  # It is set in seL4-CAmkES-L4v-dockerfiles/res/isabelle_settings.
  SKIP_DUPLICATED_PROOFS = 1;

  FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  shellHook = ''
    i() {
      ./isabelle/bin/isabelle "$@"
    }

    ij() {
      i jedit -d .
    }

    ijb() {
      ij -R $1
    }
  '';
}
