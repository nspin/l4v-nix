{ stdenv, fetchFromGitHub
, polyml, graphviz
, experimentalKernel ? true

, sources
}:

stdenv.mkDerivation {
  name = "hol4";

  src = sources.hol4;

  buildInputs = [
    polyml graphviz
  ];

  postPatch = ''
    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace '"/bin/mv"' '"mv"' \
      --replace '"/bin/cp"' '"cp"'
  '';

  configurePhase = ''
    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build
  '';

  installPhase = ''
    dst=$out/src/hol4
    mkdir -p $(dirname $dst)
    cp -r . $dst
    mkdir -p $out/bin
    ln -st $out/bin $dst/bin/hol*
  '';
}
