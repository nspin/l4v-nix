{ stdenv, fetchhg }:

stdenv.mkDerivation {
  pname = "isabelle-sha1";
  version = "2021-1";

  src = fetchhg {
    url = "https://isabelle.sketis.net/repos/sha1";
    rev = "e0239faa6f42";
    sha256 = "sha256-4sxHzU/ixMAkSo67FiE6/ZqWJq9Nb9OMNhMoXH2bEy4=";
  };

  buildPhase = (if stdenv.isDarwin then ''
    LDFLAGS="-dynamic -undefined dynamic_lookup -lSystem"
  '' else ''
    LDFLAGS="-fPIC -shared"
  '') + ''
    CFLAGS="-fPIC -I."
    $CC $CFLAGS -c sha1.c -o sha1.o
    $LD $LDFLAGS sha1.o -o libsha1.so
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp libsha1.so $out/lib/
  '';
}
