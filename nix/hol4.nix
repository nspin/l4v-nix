{ stdenv, fetchFromGitHub
, polyml, graphviz
, experimentalKernel ? true
}:

stdenv.mkDerivation {
  pname = "hol4";
  version = "k.12";

  src = fetchFromGitHub {
    owner = "SEL4PROJ";
    repo = "HOL";
    rev = "20d5350dfdc048463d2d645ae3ff31a7158b3075";
    sha256 = "15kyz8zqvf0sb8y047vbwnjc48753fphrrjs0nhlix3qvhcz9ki0";
  };

  buildInputs = [
    polyml graphviz
  ];

  postPatch = ''
    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace '"/bin/mv"' '"mv"' \
      --replace '"/bin/cp"' '"cp"'

    for f in tools/buildutils.sml help/src-sml/DOT; do
      substituteInPlace $f --replace '"/usr/bin/dot"' '"${graphviz}/bin/dot"'
    done
  '';

  configurePhase = ''
    dst=$out/lib/hol4-build
    mkdir -p $(dirname $dst)
    cd $NIX_BUILD_TOP
    mv $sourceRoot $dst
    cd $dst

    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build ${if experimentalKernel then "--expk" else "--stdknl"}
  '';

  installPhase = ''
    mkdir -p $out/bin
    ln -st $out/bin $dst/bin/hol*
  '';

}
