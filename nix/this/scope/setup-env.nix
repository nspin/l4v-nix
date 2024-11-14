{ lib
, writeText
, writeScript
, runtimeShell
}:

let
  # TODO(next) maxheap = 20000 ?
  # TODO(next) threads= not observed in jedit plugin options
  isabelleSettings = writeText "isabelle-settings" ''
    ML_OPTIONS="-H 2048 --maxheap 20480 --stackspace 64"

    # Also increase memory for Java and Scala frontends.
    ISABELLE_BUILD_JAVA_OPTIONS="-Xms2048m -Xmx6096m -Xss4m"
    JEDIT_JAVA_OPTIONS="-Xms128m -Xmx4096m -Xss4m"

    # Show bracket syntax for implications
    ISABELLE_JEDIT_OPTIONS="-m brackets"

    ISABELLE_BUILD_OPTIONS=''${OVERRIDE_ISABELLE_BUILD_OPTIONS:-"threads=6"}

    ISABELLE_HEAPS=$ISABELLE_HOME_USER/heaps/by-config/$L4V_NAME
  '';

  jeditProperties = writeText "jedit-properties" ''
    view.fontsize=18
  '';

in
writeScript "setup.sh" ''
  #!${runtimeShell}
  set -eux

  install_file() {
    src=$1
    dst=$2

    if [ -e "$dst" ]; then
      echo "warning: $dst already exists" >&2
      # echo "error: $dst already exists" >&2
      # exit 1
    else
      mkdir -p "$(dirname "$dst")"
      cp --no-preserve=mode,ownership "$src" "$dst"
    fi
  }

  install_file ${isabelleSettings} "$HOME/.isabelle/etc/settings"
  install_file ${jeditProperties} "$HOME/.isabelle/jedit/properties"

  sleep inf
''
