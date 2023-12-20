{ lib
, stdenv
, fetchurl
, fetchFromGitHub
, coreutils
, bash
, rlwrap
, makeFontsConf
, keepBuildTree
, ripgrep

, isabelleForL4vCommon
}:

let
  isabelleSource = lib.cleanSource ../../../../../../tmp/src/isabelle;

  metaComponent = isabelleForL4vCommon.mkMetaComponent isabelleSource;

in
stdenv.mkDerivation {
  pname = "isabelle";
  version = "2023";

  src = isabelleSource;

  FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  nativeBuildInputs = [
    keepBuildTree
    ripgrep
  ];

  patches = [
    ./permissions.patch
  ];

  postPatch = ''
    # patchShebangs lib/Tools/ src/Tools/ bin/
    patchShebangs .

    echo ISABELLE_LINE_EDITOR=${rlwrap}/bin/rlwrap >>etc/settings

    substituteInPlace lib/Tools/env \
      --replace /usr/bin/env ${coreutils}/bin/env

    substituteInPlace src/Tools/Setup/src/Environment.java \
      --replace 'cmd.add("/usr/bin/env");' "" \
      --replace 'cmd.add("bash");' "cmd.add(\"${bash}/bin/bash\");"

    echo ${metaComponent} >> etc/components
  '';

  buildPhase = ''
    export HOME=$(mktemp -d --suffix=-home)

    bin/isabelle jedit -bf
    # bin/isabelle build -bv HOL-Word

    bin/isabelle build -v -o system_heaps -b HOL
  '';

  checkPhase = ''
    bin/isabelle build -v HOL-SMT_Examples
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv $TMP/$dirname $out
    cd $out/$dirname
    bin/isabelle install $out/bin
  '';

  passthru = {
    inherit metaComponent;
  };
}
