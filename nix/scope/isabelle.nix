{ stdenv
, fetchurl
, perl, nettools, java, polyml, z3, rlwrap

, coreutils
, isabelle-sha1
}:

stdenv.mkDerivation rec {
  pname = "isabelle";
  version = "2020";

  dirname = "Isabelle${version}";

  src = fetchurl {
    url = "https://isabelle.in.tum.de/website-${dirname}/dist/${dirname}_linux.tar.gz";
    sha256 = "1bibabhlsvf6qsjjkgxcpq3cvl1z7r8yfcgqbhbvsiv69n3gyfk3";
  };

  buildInputs = [ perl polyml z3  nettools java ];

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
      ISABELLE_JDK_HOME=${java}
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
          '"${isabelle-sha1}/lib/libsha1.so"'
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv $TMP/$dirname $out
    cd $out/$dirname
    bin/isabelle install $out/bin
  '';
}
