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
, texliveEnv
, cppLink
}:

let
  isabelleSettings = writeText "isabelle-settings" ''
    # Setup components.
    init_components "$USER_HOME/.isabelle/contrib" "$ISABELLE_HOME/Admin/components/main"
    init_components "$USER_HOME/.isabelle/contrib" "$ISABELLE_HOME/Admin/components/bundled"

    # 10GB should be enough, even for large C proofs
    ML_OPTIONS="-H 2048 --maxheap 10000 --stackspace 64"

    ISABELLE_BUILD_OPTIONS="threads=4"

    # Also increase memory for Java and Scala frontends.
    ISABELLE_BUILD_JAVA_OPTIONS="-Xms2048m -Xmx6096m -Xss4m"
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

    isabelleForL4v
    isabelleForL4v.mlton

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
    settings_path=$HOME/.isabelle/etc/settings
    if [ -f "$settings_path" ]; then
      if ! diff -q ${isabelleSettings} $settings_path; then
        echo "unexpected contents in $settings_path" >&2
        exit 1
      fi
    else
      mkdir -p $(dirname $settings_path)
      cp --no-preserve=mode,ownership ${isabelleSettings} $settings_path
    fi
  '';
}
