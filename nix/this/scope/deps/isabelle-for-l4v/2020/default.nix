{ stdenv
, callPackage
, fetchurl, fetchhg
, perl, nettools
, openjdk11
, rlwrap, coreutils
, makeFontsConf
}:

let
  polyml = callPackage ./polyml.nix {};

  z3 = callPackage ./z3.nix { };

  sha1 = stdenv.mkDerivation {
    pname = "isabelle-sha1";
    version = "2021-1";

    src = fetchhg {
      url = "https://isabelle.sketis.net/repos/sha1";
      rev = "e0239faa6f42";
      sha256 = "sha256-4sxHzU/ixMAkSo67FiE6/ZqWJq9Nb9OMNhMoXH2bEy4=";
    };

    buildPhase = ''
      LDFLAGS="-fPIC -shared"
      CFLAGS="-fPIC -I."
      $CC $CFLAGS -c sha1.c -o sha1.o
      $LD $LDFLAGS sha1.o -o libsha1.so
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp libsha1.so $out/lib/
    '';
  };

in
stdenv.mkDerivation rec {
  pname = "isabelle";
  version = "2020";

  dirname = "Isabelle${version}";

  src = fetchurl {
    url = "https://isabelle.in.tum.de/website-${dirname}/dist/${dirname}_linux.tar.gz";
    sha256 = "1bibabhlsvf6qsjjkgxcpq3cvl1z7r8yfcgqbhbvsiv69n3gyfk3";
  };

  buildInputs = [ perl polyml z3 nettools openjdk11 ];

  FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  sourceRoot = dirname;

  postPatch = ''
    patchShebangs .

    cat >contrib/z3*/etc/settings <<EOF
      Z3_HOME=${z3}
      Z3_VERSION=${z3.version}
      Z3_SOLVER=${z3}/bin/z3
      Z3_INSTALLED=yes
    EOF

    cat >contrib/polyml-*/etc/settings <<EOF
      ML_SYSTEM_64=true
      ML_SYSTEM=${polyml.name}
      ML_PLATFORM=${stdenv.system}
      ML_HOME=${polyml}/bin
      ML_OPTIONS="--minheap 1000"
      POLYML_HOME="\$COMPONENT"
      ML_SOURCES="\$POLYML_HOME/src"
    EOF

    cat >contrib/jdk*/etc/settings <<EOF
      ISABELLE_JAVA_PLATFORM=${stdenv.system}
      ISABELLE_JDK_HOME=${openjdk11}
    EOF

    echo ISABELLE_LINE_EDITOR=${rlwrap}/bin/rlwrap >>etc/settings

    for comp in contrib/jdk* contrib/polyml-* contrib/z3-*; do
      rm -rf $comp/x86*
    done

    arch=x86_64-linux
    for f in contrib/*/$arch/{bash_process,epclextract,eprover,nunchaku,SPASS}; do
      patchelf --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) "$f"
    done

    substituteInPlace \
      lib/Tools/env \
        --replace /usr/bin/env ${coreutils}/bin/env

    substituteInPlace \
      src/Pure/General/sha1.ML \
        --replace \
          '"$ML_HOME/" ^ (if ML_System.platform_is_windows then "sha1.dll" else "libsha1.so")' \
          '"${sha1}/lib/libsha1.so"'
  '';

  configurePhase = ''
    export HOME=$(mktemp -d --suffix=-home)
  '';

  buildPhase = ''
    bin/isabelle build -v -o system_heaps -b Pure HOL HOL-Word
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv $TMP/$dirname $out
    cd $out/$dirname
    bin/isabelle install $out/bin
  '';

  passthru = {
    inherit sha1;
  };
}
