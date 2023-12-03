{ lib, stdenv
, runCommand
, writeText
, makeFontsConf
, python3Packages
, haskellPackages
, rsync, git, perl, hostname, which, cmake, ninja, dtc, libxml2

, sources
, scopeConfig
, mltonForL4v
, isabelleForL4v
, texliveEnv
, ghcWithPackagesForL4v

, breakpointHook, bashInteractive
, strace
}:

{ name ? null

, tests ? null
, exclude ? []
, remove ? []
, verbose ? false
, numJobs ? 1
, timeouts ? false
, timeoutScale ? null

, overlay ? null

, buildStandaloneCParser ? false
, simplExport ? false

, isabelleLink ? buildStandaloneCParser
}:

# NOTE
# The default Isabelle settings seem to be working. Nevertheless, we should consider experimenting
# with some from:
# - l4v/misc/etc/settings
# - seL4-CAmkES-L4v-dockerfiles/res/isabelle_settings

# TODO
# Consider exporting the entire top-level

# TODO
# Debug the following for (at least) justStandaloneCParser:
# *** Consumer thread failure: "Isabelle.Session.manager"
# *** Missing session sources entry "/build/src/l4v/tools/c-parser/umm_

assert tests == null -> (exclude == [] && remove == []);

let
  # Selected from l4v/misc/etc/settings
  # TODO tune
  settings = writeText "settings" ''
    ML_OPTIONS="-H 1000 --maxheap 10000 --stackspace 64"
    ISABELLE_BUILD_JAVA_OPTIONS="-Xms2048m -Xmx6096m -Xss4m"
  '';

in
stdenv.mkDerivation {
  name = "l4v${lib.optionalString (name != null) "-${name}"}";

  nativeBuildInputs = [
    rsync git perl hostname which cmake ninja dtc libxml2

    mltonForL4v

    ghcWithPackagesForL4v
    haskellPackages.cabal-install

    python3Packages.sel4-deps

    texliveEnv

    scopeConfig.targetCC
    scopeConfig.targetBintools

    # breakpointHook bashInteractive
    # strace
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

  unpackPhase = ''
    d=src

    mkdir $d
    ln -s ${isabelleForL4v} $d/isabelle
    ln -s ${sources.seL4} $d/seL4
    cp -r ${sources.l4v} $d/l4v

    sourceRoot=$d/l4v

    chmod -R u+w -- $sourceRoot
  '';

  postPatch = ''
    cpp_files="
      tools/c-parser/isar_install.ML
      tools/c-parser/standalone-parser/tokenizer.sml
      tools/c-parser/standalone-parser/main.sml
      tools/c-parser/testfiles/jiraver313.thy
      "
    for x in $cpp_files; do
      substituteInPlace $x --replace \
        /usr/bin/cpp \
        ${scopeConfig.targetCC}/bin/${scopeConfig.targetPrefix}cpp
    done

    substituteInPlace spec/Makefile --replace \
      '$(ASPEC_GITREV_FILE): .FORCE' \
      '$(ASPEC_GITREV_FILE):'

    pwd | tr -d '\n' > spec/abstract/document/git-root.tex

    echo -n unknown > spec/abstract/document/gitrev.tex

    substituteInPlace spec/ROOT --replace \
      'document=pdf' \
      'document=pdf, document_output="output"'
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    export ISABELLE_HOME=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME')

    isabelle_home_user=$(./isabelle/bin/isabelle env sh -c 'echo $ISABELLE_HOME_USER')
    settings_dir=$isabelle_home_user/etc
    mkdir -p $settings_dir
    cp ${settings} $settings_dir/settings

    mkdir -p $HOME/.cabal
    touch $HOME/.cabal/config

  '' + lib.optionalString (scopeConfig.arch != "X64") (
    let
      overlayDir = "spec/cspec/c/overlays/${scopeConfig.arch}";
      overlayOrDefault = if overlay != null then overlay else "${overlayDir}/default-overlay.dts";
    in ''
      if [ -e ${overlayDir} ]; then
        cp ${overlayOrDefault} ${overlayDir}/overlay.dts
      fi
    ''
  );

  # TODO wrap './run_tests' in 'time' invocation
  buildPhase = ''
    ${lib.optionalString (tests != null) ''
      time ./run_tests \
        ${lib.optionalString verbose "-v"} \
        ${lib.optionalString (!timeouts) "--no-timeouts"} \
        ${lib.optionalString (timeoutScale != null) "--scale-timeouts ${toString timeoutScale}"} \
        -j ${toString numJobs} \
        ${lib.concatMapStringsSep " " (test: "-x ${test}") exclude} \
        ${lib.concatMapStringsSep " " (test: "-r ${test}") remove} \
        ${lib.concatStringsSep " " tests}

      rm -rf spec/abstract/output/document
    ''}

    ${lib.optionalString buildStandaloneCParser ''
      time make -C tools/c-parser/standalone-parser standalone-cparser
    ''}

    ${lib.optionalString simplExport ''
      time make -C proof/ SimplExport
    ''}
  '' + lib.optionalString isabelleLink ''
    ln -sfT ${isabelleForL4v} isabelle
  '';

  installPhase = ''
    cp -r . $out
  '';

  dontFixup = true;
}
