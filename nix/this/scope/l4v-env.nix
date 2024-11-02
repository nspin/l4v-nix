{ lib
, mkShell
, writeText
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

let
  isabelleSettings = writeText "isabelle-settings" ''
    ML_OPTIONS="-H 2048 --maxheap 10000 --stackspace 64"

    ISABELLE_BUILD_JAVA_OPTIONS="-Xms2048m -Xmx6096m -Xss4m"

    ISABELLE_BUILD_OPTIONS="threads=4"

    # Also increase memory for Java and Scala frontends.
    JEDIT_JAVA_OPTIONS="-Xms128m -Xmx4096m -Xss4m"

    # Show bracket syntax for implications
    ISABELLE_JEDIT_OPTIONS="-m brackets"
  '';

  # TODO jedit_reset_font_size : int = 18
  jeditProperties = writeText "jedit-properties" ''
  '';

in
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
  TOOLPREFIX = scopeConfig.targetPrefix;

  # TODO
  # What does this do?
  # Is it appropriate?
  # It is set in seL4-CAmkES-L4v-dockerfiles/res/isabelle_settings.
  SKIP_DUPLICATED_PROOFS = 1;

  FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  shellHook = ''
    ensure_file() {
      src=$1
      dst=$2

      if [ -f "$dst" ]; then
        if ! diff -q "$src" "$dst"; then
          echo "unexpected contents in $dst" >&2
          exit 1
        fi
      else
        mkdir -p "$(dirname "$dst")"
        cp --no-preserve=mode,ownership "$src" "$dst"
      fi
    }

    ensure_file ${isabelleSettings} "$HOME/.isabelle/etc/settings"
  '';
}
